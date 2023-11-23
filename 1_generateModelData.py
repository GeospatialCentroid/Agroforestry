import ee
import geemap
import geopandas as gpd
from agroforestry.config import * 
from agroforestry.geeHelpers import *
from agroforestry.naipProcessing import *
from agroforestry.snicProcessing import *


# establish connection with ee account. might require some additional configuration based on local machine 
ee.Initialize()
# if issues see 0_develop training data for suggestions 

# import training dataset 
trainingData = gpd.read_file(filename="data/processed/trainingdataset.geojson")
print(trainingData)
# convert to ee object
# pointsEE = geemap.gdf_to_ee(trainingData)

# define our aoi 
aoiID <- 'X12-695' # something to itorate over 
# this becomes the AOI to used in the prepNAIP function. I'll need to edit it so that it converts the input data into a bbox 
print(grid)


# # generate NAIP layer 
# naipEE = prepNAIP(aoi=pointsEE, year=year)
# # geePrint(naipEE)

# # normal the naip data
# normalizedNAIP = normalize_by_maxes(img=naipEE, bandMaxes=bandMaxes)

# # # produce the SNIC object 
# snicData = snicOutputs(naip = normalizedNAIP, SNIC_NeighborhoodSize = SNIC_NeighborhoodSize,
#                        SNIC_SeedShape = SNIC_SeedShape, SNIC_SuperPixelSize = SNIC_SuperPixelSize, 
#                        SNIC_Compactness = SNIC_Compactness, SNIC_Connectivity = SNIC_Connectivity,
#                        nativeScaleOfImage = nativeScaleOfImage, bandsToUse_Cluster = bandsToUse_Cluster)