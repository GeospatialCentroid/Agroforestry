# filePath = "testing/data/testSamplingData.geojson"


def establishSamplingPoints(filePath):
  # read in the data
  s = gpd.read_file(filePath)
  # convert to an ee object 
  sp1 = geemap.gdf_to_ee(s)
  # return feature
  return(sp1)


  
