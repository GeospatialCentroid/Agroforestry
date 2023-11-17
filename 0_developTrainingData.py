import ee
import os
import geemap 
import geopandas as gpd
# import agroforestry
from agroforestry.config import * 

# establish connection with ee account. might require some additional configuration based on local machine 
ee.Initialize()
# if initialization, comment out the line above and go through the authentication process
## don't expect this to go smoothly or quickly... 
#try this first
# ee.Authenticate() 
## pursue the gcloud installation if you have the time and will be utilizing your current machine in the future 
## if your short on time you can use the notebook authentication which will give you about a week of use on the current machine 
# ee.Authenticate(auth_mode = notebook)


print("training data is being develop for the " + str(year)+ " time period")

# Generate NAIP object based on the AOI of the sampling data (points : define in config file)
# naipEE = prepNAIP(aoi = points , year = year)

# still not able to get functions brought in from the file folder so trying something else 
def geePrint(feature):
    return print(feature.getInfo())
# geePrint(geemap.gdf_to_ee(points))


## 1.1 Simple normalization by maxes function.
## It's important in the clusting step that all bands have the same range. 
## img = input image 
## bandMaxes = vect of values reflecting the specific max values in a given band (unique to imagery source)
def afn_normalize_by_maxes(img, bandMaxes):
    return img.divide(bandMaxes)

def prepNAIP(year,aoi):
    # convert AOI to a gg object 
      sp1 = aoi
    # grab naip for the year of interest, filter, mask, mosaic to a single image
      naip1 = geemap.get_annual_NAIP(year).filterBounds(sp1).mosaic()  
    # Generate NDVI 
      ndvi = naip1.normalizedDifference(["N","R"])
    # generate other indicies 

    # # Bind all the bands together 
      naip = naip1.addBands(ndvi)
    # export a ee object of the NAIP imagery 
      return naip

# big function that produces the segementation model 
def snicOutputs(naip, bandMaxes, SNIC_NeighborhoodSize,SNIC_SeedShape,
                 SNIC_SuperPixelSize, SNIC_Compactness, SNIC_Connectivity, 
                 nativeScaleOfImage,bandsToUse_Cluster):
       # normalize the NAIP data
       naip2 = afn_normalize_by_maxes(img=naip,
                                       bandMaxes=bandMaxes)
       # develop a seed grid for the segemetation process
       seed1 = ee.Algorithms.Image.Segmentation.seedGrid(size = SNIC_NeighborhoodSize,
                                                         gridType = SNIC_SeedShape)

       # run the cluster algorytm
       snic = ee.Algorithms.Image.Segmentation.SNIC(image = naip2,
                                                    size = SNIC_SuperPixelSize,
                                                    compactness = SNIC_Compactness,
                                                    connectivity = SNIC_Connectivity,
                                                    neighborhoodSize = SNIC_NeighborhoodSize,
                                                    seeds = seed1)
       
       # reproject to ensure that clusters are drawn at the native resolution
       snic_Proj=snic.reproject(crs = 'EPSG:3857', scale = nativeScaleOfImage)

        # select specific bands and combine with original image
       snic2 = snic_Proj.select(bandsToUse_Cluster).addBands(naip2)

       # return ee image 
       return snic2
     
# convert the reference points to gee object 
pointsEE = geemap.gdf_to_ee(points)

# generate NAIP layer 
naipEE = prepNAIP(aoi=pointsEE, year=year)
# print(naipEE)

# produce the SNIC object 
snicData = snicOutputs(naip = naipEE, bandMaxes = bandMaxes, SNIC_NeighborhoodSize = SNIC_NeighborhoodSize,
                       SNIC_SeedShape = SNIC_SeedShape, SNIC_SuperPixelSize = SNIC_SuperPixelSize, 
                       SNIC_Compactness = SNIC_Compactness, SNIC_Connectivity = SNIC_Connectivity,
                       nativeScaleOfImage = nativeScaleOfImage, bandsToUse_Cluster = bandsToUse_Cluster)
# geePrint(snicData)

# extract values for the training and testing datasets 
extractedReferenceData = snicData.sampleRegions(collection = pointsEE, 
                                                scale = nativeScaleOfImage,
                                                geometries = False)
# export data 
refData = geemap.ee_to_geojson(ee_object=extractedReferenceData,
                               filename="data/processed/trainingdataset.geojson")
                               
geePrint(extractedReferenceData)
