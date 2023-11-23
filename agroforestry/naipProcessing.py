


# Gather the naip  image and generate additional indicies 
def prepNAIP(year,aoi):
      import geemap
    # # convert AOI to a gg object 
    #   sp1 = geemap.gdf_to_ee(aoi)
    # grab naip for the year of interest, filter, mask, mosaic to a single image
      naip1 = geemap.get_annual_NAIP(year).filterBounds(aoi).mosaic()  
    # Generate NDVI 
      ndvi = naip1.normalizedDifference(["N","R"])
    # generate other indicies -- texture based measures specifically 


    # Bind all the bands together 
      naip = naip1.addBands(ndvi)
    # export a ee object of the NAIP imagery 
      return naip


## Simple normalization by maxes function.
## It's important in the clusting step that all bands have the same range. 
## img = input image 
## bandMaxes = vect of values reflecting the specific max values in a given band (unique to imagery source)
def normalize_by_maxes(img, bandMaxes):
    return img.divide(bandMaxes)