# aoiObject = aoi_ee
# year = 2016

def prepNAIP(aoiObject, year):
  # grab naip for area and year 
  naip = geemap.get_annual_NAIP(year).filterBounds(aoi_ee).mosaic()
  # generate NDVI 
  ndvi = naip.normalizedDifference(["N","R"])
  # add ndvi to naip image 
  naip = naip.addBands(ndvi)
  # return imagery
  return(naip)


