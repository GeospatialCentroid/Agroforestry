## function to download data from ee
# aoi = "~/Documents/Agroforestry/testing/subgrid.gpkg"
# year = 2016
# downloadPath = "testing/Downloads"

def downloadNAIP(aoi, year, downloadPath): 
  # read in reference grid dataset
  sp = gpd.read_file(aoi)
  # convert it to a GEE object to use as the primary aoi for naip call.
  sp_ee = geemap.gdf_to_ee(sp)
  # grab naip and filter it to aoi 
  naip = geemap.get_annual_NAIP(str(year)).filterBounds(sp_ee).mosaic()
  # construct file name 
  size = sp_ee.size().getInfo()
  for i in range(size): # set to size when running
    print(i)
    # grab a subset of the area 
    sp2 = sp.iloc[[i]]
    # convert to gee object for 
    sp_ee2 = geemap.gdf_to_ee(sp2).geometry()
    # filter the image 
    image = naip.clip(sp_ee2)
    # define file name 
    filename = filename = downloadPath + "/naip"+str(year)+"_" + str(i) + ".tif"
    geemap.ee_export_image(
        image,
        filename=filename,
        scale = 1, # scale in meters probably best to call best on x,y of image rather then define.
        region=sp_ee2,
        file_per_band=False)

        
