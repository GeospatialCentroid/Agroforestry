


# Gather the naip  image and generate additional indicies 
def prepNAIP(year,aoi):
    import geemap
    # # convert AOI to a gg object 
    # sp1 = aoi.bounds()
    # grab naip for the year of interest, filter, mask, mosaic to a single image
    naip1 = geemap.get_annual_NAIP(year).filterBounds(aoi).mosaic()  
    # Generate NDVI 
    ndvi = naip1.normalizedDifference(["N","R"])
    # generate GLCM
    glcm_g = naip1.select('G').glcmTexture(size = windowSize).select(['G_contrast','G_corr','G_ent'], ["contrast_g","corr_g", "entropy_g"])
    glcm_n = naip1.select('N').glcmTexture(size= windowSize).select(['N_contrast','N_corr','N_ent'], ["contrast_n","corr_n", "entropy_n"])
    # add to naip 
    naip2 = naip1.addBands(glcm_g).addBands(glcm_n)

    # average and standard deviation NDVI
    ndvi_sd =  ndvi.select('nd').reduceNeighborhood(reducer = ee.Reducer.stdDev(),kernel = ee.Kernel.circle(windowSize))
    ndvi_mean =  ndvi.select('nd').reduceNeighborhood(reducer= ee.Reducer.mean(),  kernel= ee.Kernel.circle(windowSize))

    # Bind ndvi after the glcm processall the bands together 
    naip = naip2.addBands(ndvi).addBands(ndvi_sd).addBands(ndvi_mean)
    # export a ee object of the NAIP imagery 
    return naip


## Simple normalization by maxes function.
## It's important in the clusting step that all bands have the same range. 
## img = input image 
## bandMaxes = vect of values reflecting the specific max values in a given band (unique to imagery source)
def normalize_by_maxes(img, bandMaxes):
    return img.divide(bandMaxes)