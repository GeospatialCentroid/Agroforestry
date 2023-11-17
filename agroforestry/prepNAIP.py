

def prepNAIP(year,aoi):
      import geemap
    # convert AOI to a gg object 
      sp1 = geemap.gdf_to_ee(aoi)
    # grab naip for the year of interest, filter, mask, mosaic to a single image
      naip1 = geemap.get_annual_NAIP(year).filterBounds(sp1).mosaic()  
    # Generate NDVI 
      ndvi = naip1.normalizedDifference(["N","R"])
    # generate other indicies 

    # Bind all the bands together 
      naip = naip1.addBands(ndvi)
    # export a ee object of the NAIP imagery 
      return naip
