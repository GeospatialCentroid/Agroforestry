

import ee
import geemap
import os
import geopandas as gpd

## authenticate/initialize gee
# ee.Authenticate()
ee.Initialize()





# read in reference grid dataset
sp = gpd.read_file("data/griddedFeatures/twelve_mi_grid_uid.gpkg")
# convert it to a GEE object to use as the primary aoi for naip call.
sp_ee = geemap.gdf_to_ee(sp)

# grab naip and filter it to aoi 
naip2015 = geemap.get_annual_NAIP(2016).filterBounds(sp_ee).mosaic() # .filterBounds(trees_ee) not liking this object. 

# defile download path 
out_dir = os.path.join(os.path.expanduser('~'), 'Downloads')

# grab a subset of the area 
sp2 = sp.iloc[[0]]
sp_ee2 = geemap.gdf_to_ee(sp2).geometry()
sp_ee2

# define the file name based onthe selected object 
filename = "referenceGrid_0.tif" # need to construct this

# loop over features in the aoi object and download files 
size = sp_ee.size().getInfo()-1
for i in range(1): # set to size when running
    print(i)
    # grab a subset of the area 
    sp2 = sp.iloc[[i]]
    # convert to gee object for 
    sp_ee2 = geemap.gdf_to_ee(sp2).geometry()
    # filter the image 
    image = naip2015.clip(sp_ee2)
    # define file name 
    filename = filename = "naip2015_" + str(i) + ".tif"
    # download to file 
    # geemap.ee_export_image(
    #     image,
    #     filename=filename,
    #     scale = 1, # scale in meters probably best to call best on x,y of image rather then define. 
    #     region=sp_ee2,
    #     file_per_band=False)

Generating URL ...
Downloading data from https://earthengine.googleapis.com/v1/projects/earthengine-legacy/thumbnails/ea4a1a1a13f41fbe35671bf5f360a263-94758645c8688d1cac919a78da1fcce6:getPixels
Please wait ...
Data downloaded to E:\geoSpatialCentroid\Agroforestry\testing\naip2015_0.tif

 range(0)

range(0, 0)

