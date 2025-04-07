import ee
import geemap

Grids = ee.FeatureCollection("projects/agroforestry2023/assets/twelve_mi_shp")
def getGridArea(gridID):
    Grid = ee.Feature(Grids.filter(ee.Filter.eq('Unique_ID', gridID)).first())
    return Grid

def getNAIP(gridArea, year):
    # """Input: A feature object. Output: An ee.Image (NAIP imagery mosaic cropped to the bounds of the input feature)."""
    region = gridArea.geometry()
    naip = geemap.get_annual_NAIP(year).filterBounds(region).mosaic().clip(region).select(['R', 'G', 'B', 'N'])
    return naip


# Methods
def rectanglify(gridArea):
    """Input: A feature object. Output: An ee.FeatureCollection containing 8 features (vertical slices)."""
    bounds = gridArea.geometry().bounds()
    coords = ee.List(bounds.coordinates().get(0))
    lowerLeft = ee.List(coords.get(0))
    lowerRight = ee.List(coords.get(1))
    upperRight = ee.List(coords.get(2))
    minX = ee.Number(lowerLeft.get(0))
    minY = ee.Number(lowerLeft.get(1))
    maxX = ee.Number(lowerRight.get(0))
    maxY = ee.Number(upperRight.get(1))
    width = maxX.subtract(minX)

    def create_rectangle(i):
        i = ee.Number(i)
        xStart = minX.add(width.multiply(i).divide(8))
        xEnd = minX.add(width.multiply(i.add(1)).divide(8))
        rectangle = ee.Geometry.Rectangle([xStart, minY, xEnd, maxY])
        return ee.Feature(rectangle, {})

    rectFeatures = ee.FeatureCollection(ee.List.sequence(0, 7).map(create_rectangle))
    return rectFeatures

def sliceNAIP(image, slicesFeatureCollection):
    """Input: a NAIP image and a FeatureCollection of rectangle slices. Output: an ImageCollection where each image is the NAIP image clipped to one slice."""
    rectList = slicesFeatureCollection.toList(slicesFeatureCollection.size())

    def clip_image(rectFeature):
        rectFeature = ee.Feature(rectFeature)
        geom = rectFeature.geometry()
        return image.clip(geom)

    slices = rectList.map(clip_image)
    return ee.ImageCollection(slices)

def cumsumArray(arr):
    """Calculates the cumulative sum of an ee.Array."""
    arrList = arr.toList()

    def cumsum_iter(x, acc):
        acc = ee.List(acc)
        last = ee.Number(ee.Algorithms.If(acc.size().gt(0), acc.get(acc.size().subtract(1)), 0))
        return acc.add(ee.Number(x).add(last))

    cumsumList = ee.List(arrList).iterate(cumsum_iter, ee.List([]))
    return ee.Array(cumsumList)

# Histogram Matching Functions
def matchBand(sourceImage, referenceImage, bandName):
    """Matches the histogram of a single band."""
    sourceGeom = sourceImage.geometry().bounds()
    refGeom = referenceImage.geometry().bounds()

    sourceHist = sourceImage.reduceRegion(
        reducer=ee.Reducer.fixedHistogram(0, 255, 256),
        geometry=sourceGeom,
        scale=30,
        maxPixels=1e9,
        bestEffort=True
    )

    referenceHist = referenceImage.reduceRegion(
        reducer=ee.Reducer.fixedHistogram(0, 255, 256),
        geometry=refGeom,
        scale=30,
        maxPixels=1e9,
        bestEffort=True
    )

    sourceCounts = ee.Array(sourceHist.get(bandName)).slice(1, 1, 2).project([0])
    referenceCounts = ee.Array(referenceHist.get(bandName)).slice(1, 1, 2).project([0])
    sourceSum = ee.Number(sourceCounts.reduce(ee.Reducer.sum(), [0]).get([0]))
    referenceSum = ee.Number(referenceCounts.reduce(ee.Reducer.sum(), [0]).get([0]))
    sourceCDF = cumsumArray(sourceCounts.divide(sourceSum))
    referenceCDF = cumsumArray(referenceCounts.divide(referenceSum))
    sourceCDFList = ee.List(sourceCDF.toList())
    referenceCDFList = ee.List(referenceCDF.toList())

    def create_lookup(i):
        i = ee.Number(i)
        p = ee.Number(sourceCDFList.get(i))
        differences = referenceCDFList.map(lambda r: ee.Number(r).subtract(p).abs())
        minDiff = ee.Number(differences.sort().get(0))
        matchedIndex = ee.Number(differences.indexOf(minDiff))
        return matchedIndex

    lookupTable = ee.List.sequence(0, 255).map(create_lookup)
    return sourceImage.select(bandName).remap(ee.List.sequence(0, 255), lookupTable).rename(bandName).toUint8()

def matchAllBands(sourceImage, referenceImage, bandNames):
    """Matches histograms for all specified bands."""
    images = [matchBand(sourceImage, referenceImage, band) for band in bandNames]
    return ee.Image.cat(images)

def sampleImage(image, samplePoints, fileDesc):
    """Samples an image and exports the results to Google Drive."""
    samples = image.sampleRegions(
        collection=samplePoints,
        scale=1
    )
    task = ee.batch.Export.table.toDrive(
        collection=samples,
        description=fileDesc,
        fileFormat='csv',
        folder='Agroforestry'
    )
    task.start()
    print(f'Export task {fileDesc} started.')

def matchSelf(gridArea, year, verbose=False, sample=False):
    """Processes grids by matching each grid's histogram to itself."""
    mosaics = []
    gridFeatures = []

    # for id in gridIDs:
    if verbose:
        print(f"Processing grid (matchSelf): {id}")
    # gridArea = getGridArea(id)
    gridFeatures.append(gridArea)
    if verbose:
        print(f'Map.addLayer(gridArea, {{}}, "{id} region")') #replace with desired python mapping library
    naipImage = getNAIP(gridArea, year)
    if verbose:
        print(f'Map.addLayer(naipImage, {{}}, "{id} NAIP imagery")')#replace with desired python mapping library
    rectFeatures = rectanglify(gridArea)
    if verbose:
        print(f'Map.addLayer(rectFeatures, {{color: "red"}}, "{id} divided region")')#replace with desired python mapping library
    slicesCollection = sliceNAIP(naipImage, rectFeatures)
    if verbose:
        print(f'Map.addLayer(slicesCollection, {{}}, "{id} NAIP slices")')#replace with desired python mapping library
    gridSamplePoints = ee.FeatureCollection.randomPoints(region=gridArea.geometry(), points=100, seed=5)
    if sample:
        sampleImage(naipImage, gridSamplePoints, f"{id}OriginalNAIPSampling")
    if sample:
        print(f'Map.addLayer(gridSamplePoints, {{color: "green"}}, "{id} Grid Sample Points")') #replace with desired python mapping library
        print(gridSamplePoints, f"{id} Grid Sample Points")
    origSlicesList = slicesCollection.toList(slicesCollection.size())
    numSlices = slicesCollection.size().getInfo()
    sliceSamples = []
    for i in range(numSlices):
        slice_img = ee.Image(origSlicesList.get(i))
        sliceGeom = slice_img.geometry()
        sliceSamplePoints = ee.FeatureCollection.randomPoints(region=sliceGeom, points=100, seed=5)
        sliceSamples.append(sliceSamplePoints)
        if sample:
            sampleImage(slice_img, sliceSamplePoints, f"{id}OriginalSlice_{i}Sampling")
        if sample:
            print(f'Map.addLayer(sliceSamplePoints, {{color: "orange"}}, "{id} Original Slice {i} Sample Points")') #replace with desired python mapping library
            print(sliceSamplePoints, f"{id} Original Slice {i} Sample Points")
    referenceSlice = ee.Image(origSlicesList.get(numSlices - 1))
    bands = ['R', 'G', 'B', 'N']
    def correct_slice(slice_img):
        return matchAllBands(slice_img, referenceSlice, bands)
    correctedSlices = slicesCollection.map(correct_slice)
    correctedMosaic = correctedSlices.mosaic()
    if verbose:
        print(f'Map.addLayer(correctedMosaic, {{}}, "{id} Corrected NAIP")') #replace with desired python mapping library
    if sample:
        sampleImage(correctedMosaic, gridSamplePoints, f"{id}HistogramMatchSampling")
    mosaics.append(correctedMosaic)
    ########################################
    # The below line does not work in GEE python and throws an error saying:
    # unionGeom = ee.FeatureCollection(gridFeatures).geometry()
    # Unable to use a collection in an algorithm that requires a feature or image. This may happen when trying to use
    # a collection of collections where a collection of features is expected; use flatten, or map a function to convert
    # inner collections to features. Use clipToCollection (instead of clip) to clip an image to a collection.
    # Added flatten() and worked.
    ########################################
    unionGeom = ee.FeatureCollection(gridFeatures).flatten().geometry()
    mosaicImage = ee.ImageCollection(mosaics).mosaic().clip(unionGeom)
    return mosaicImage


def matchGrid(gridIDs, referenceImage, year, verbose=False, sample=False):
    """Matches grids in gridIDs to a reference mosaic."""
    mosaics = []
    gridFeatures = []

    refImage = ee.Image(referenceImage)
    if verbose:
        print("Reference image for matching (entire corrected mosaic):", refImage)
        print(f'Map.addLayer(refImage, {{min: 0, max: 255}}, "Reference Mosaic")')  # replace with desired python mapping library

    for id in gridIDs:
        if verbose:
            print(f"Processing grid (matchGrid): {id}")

        gridArea = getGridArea(id)
        gridFeatures.append(gridArea)
        if verbose:
            print(f'Map.addLayer(gridArea, {{}}, "{id} region")')  # replace with desired python mapping library

        naipImage = getNAIP(gridArea, year)
        if verbose:
            print(f'Map.addLayer(naipImage, {{}}, "{id} NAIP imagery")')  # replace with desired python mapping library

        rectFeatures = rectanglify(gridArea)
        if verbose:
            print(f'Map.addLayer(rectFeatures, {{color: "red"}}, "{id} divided region")')  # replace with desired python mapping library

        slicesCollection = sliceNAIP(naipImage, rectFeatures)
        if verbose:
            print(f'Map.addLayer(slicesCollection, {{}}, "{id} NAIP slices")')  # replace with desired python mapping library

        gridSamplePoints = ee.FeatureCollection.randomPoints(region=gridArea.geometry(), points=100, seed=5)
        if sample:
            sampleImage(naipImage, gridSamplePoints, f"{id}OriginalNAIPSampling")
        if sample:
            print(f'Map.addLayer(gridSamplePoints, {{color: "green"}}, "{id} Grid Sample Points")')  # replace with desired python mapping library
            print(gridSamplePoints, f"{id} Grid Sample Points")

        origSlicesList = slicesCollection.toList(slicesCollection.size())
        numSlices = slicesCollection.size().getInfo()
        sliceSamples = []
        for i in range(numSlices):
            slice_img = ee.Image(origSlicesList.get(i))
            sliceGeom = slice_img.geometry()
            sliceSamplePoints = ee.FeatureCollection.randomPoints(region=sliceGeom, points=100, seed=5)
            sliceSamples.append(sliceSamplePoints)
            if sample:
                sampleImage(slice_img, sliceSamplePoints, f"{id}OriginalSlice_{i}Sampling")
            if sample:
                print(f'Map.addLayer(sliceSamplePoints, {{color: "orange"}}, "{id} Original Slice {i} Sample Points")')  # replace with desired python mapping library
                print(sliceSamplePoints, f"{id} Original Slice {i} Sample Points")

        bands = ['R', 'G', 'B', 'N']

        def correct_slice(slice_img):
            return matchAllBands(slice_img, refImage, bands)  # Use refImage here

        correctedSlices = slicesCollection.map(correct_slice)

        correctedMosaic = correctedSlices.mosaic()
        if verbose:
            print(f'Map.addLayer(correctedMosaic, {{}}, "{id} Corrected NAIP")')  # replace with desired python mapping library
        if sample:
            sampleImage(correctedMosaic, gridSamplePoints, f"{id}HistogramMatchSampling")

        mosaics.append(correctedMosaic)
    ########################################
    # The below line does not work in GEE python and throws an error saying:
    # unionGeom = ee.FeatureCollection(gridFeatures).geometry()
    # Unable to use a collection in an algorithm that requires a feature or image. This may happen when trying to use
    # a collection of collections where a collection of features is expected; use flatten, or map a function to convert
    # inner collections to features. Use clipToCollection (instead of clip) to clip an image to a collection.
    # Added flatten() and worked.
    ########################################
    unionGeom = ee.FeatureCollection(gridFeatures).geometry()
    mosaicImage = ee.ImageCollection(mosaics).mosaic().clip(unionGeom)
    return mosaicImage