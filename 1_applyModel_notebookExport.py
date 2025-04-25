# %%
import ee
import geemap
import geopandas as gpd
import numpy as np
from agroforestry.config import * 
from agroforestry.geeHelpers import *
from agroforestry.naipProcessing import *
from agroforestry.snicProcessing import *
from agroforestry.randomForest import *
from agroforestry.exportFunctions import *

# %%
# establish connection with ee account. might require some additional configuration based on local machine 
try:
        ee.Initialize(project='agroforestry2023')
except Exception as e:
        ee.Authenticate()
        ee.Initialize()# i

# %%
# # 2010 models to rerun 
# models10 = ["X12-83", "X12-83", "X12-83", "X12-83", "X12-83", "X12-83", "X12-83", "X12-150",
#  "X12-594", "X12-594", "X12-594", "X12-594", "X12-594", "X12-594",  "X12-615",
#  "X12-594"]
# ranGrid10 = [ "X12-1","X12-2","X12-3","X12-4","X12-5","X12-6", 
# "X12-7","X12-336", "X12-414", "X12-415", "X12-592", "X12-637",
# "X12-682","X12-725","X12-740","X12-766"]
# # 2016 models to rerun 
# models16 = ["X12-150", "X12-594", "X12-594", "X12-594","X12-594",
#  "X12-594","X12-594", "X12-615","X12-615"  ]
ranGrid16 = ["X12-336","X12-414","X12-415","X12-592","X12-637",
"X12-682","X12-725", "X12-740", "X12-766"]
# # 2020 models to rerun 
# models20 = ["X12-150", "X12-615"]
# ranGrid20 = ["X12-336","X12-740"]


# %%
# define the aoi
aoiID = "X12-1" # something to itorate over for now is defined based on the input training dataset 
year = 2010
# or manually define it for where you want to apply the model too
# aoiID = "X12-601"
# # this becomes the AOI to used in the prepNAIP function. I'll need to edit it so that it converts the input data into a bbox 
gridSelect = grid.loc[grid.Unique_ID == aoiID]
# manual selection 
# gridSelect = grid.loc[grid.Unique_ID == "X12-400"]


#Define bands to use
### can change this to a manually defined [] of variable names 
# bandsToUse = vsurfWithCor

# define standard variable set 
bandsToUse = ["contrast_n_mean", "entropy_n_mean", "entropy_n", 
"entropy_g_mean","nd_mean_neighborhood","contrast_n",
"entropy_g","nd_mean","contrast_g_mean","contrast_g"] 


# select multiple grids level 1 
## want to pull thing from the csv rather than write it out. 
# aoiID = grid24
# gridSelect =  grid.loc[grid.Unique_ID.isin(grid36.Unique_ID)].dissolve()
# gridSelect = "X12-400"
# after the desolve this gets assign a unique id some way. Might want to assign it the initGridID instead 
# might want to 
# len(gridSelect.Unique_ID)



# %%
gridSelect


# %%
# convert to a gee object 
aoi1 = geemap.gdf_to_ee(gridSelect)
# create a sub grid for downloading 
# downloadGrids = geemap.fishnet(aoi1.geometry(), rows=6, cols=4, delta=0)
aoi1


# %%
Map = geemap.Map(center=(42.3, -98), zoom=10)
Map.add_basemap('HYBRID')
Map.addLayer(aoi1, {'color': '000000ff',
                    'width': 2,
                    'lineType': 'solid'},
             'area of interest')
# Map.addLayer(downloadGrids, {'color': '000000ff',
#                     'width': 2,
#                     'lineType': 'solid'},
#              'area of subgrid')

Map

# %%
# import training dataset 
# trainingData = gpd.read_file(filename="data/processed/trainingdataset_withClasses.geojson")
trainingData = gpd.read_file(filename="data/processed/" + str(initGridID) +"/"+ "agroforestrySamplingData_"+str(year)+".geojson") # initGridID defined int he config file

# divide the data into test train spilts 
trainingData = trainingData.sample(frac = 1)
# get rows 
total_rows = trainingData.shape[0]
# get train size 
train_size = int(total_rows*test_train_ratio)
 
# Split data into test and train
train = trainingData[0:train_size]
test = trainingData[train_size:]
# define the GEE objects
training = geemap.gdf_to_ee(gdf=train)
testing = geemap.gdf_to_ee(gdf=test)

# # print(type(trainingData))
# # select the training class of interest and drop unnecessary columns
# trainingSubset = trainingData
# # trainingSubset =  trainingData[trainingData.sampleStrat == "original"] ## will want to drop this as we wont have multiple sampling categories 
# # print(trainingSubset)
# # convert to ee object
# pointsEE = geemap.gdf_to_ee(gdf=trainingSubset)
# # subset testing and training data 
# training = pointsEE.filter(ee.Filter.gt('random', test_train_ratio))
# testing = pointsEE.filter(ee.Filter.lte('random',test_train_ratio))
# traing the rf model 
# rfCluster = trainRFModel(bands=bandsToUse_Cluster, inputFeature=training, nTrees=nTrees,setSeed=setSeed)
# rfPixel = trainRFModel(bands=bandsToUse_Pixel, inputFeature=training, nTrees=nTrees,setSeed=setSeed)
rfPixelTrim = trainRFModel(bands=bandsToUse,  inputFeature=training, nTrees=nTrees,setSeed=setSeed )
## run validation using the testing set 
# clusterValidation = testRFClassifier(classifier=rfCluster, testingData= testing)
# pixelValidation = testRFClassifier(classifier=rfPixel, testingData= testing)
pixelValidationTrim = testRFClassifier(classifier=rfPixelTrim, testingData= testing)
print(trainingData)

# %%
geePrint(training)


# %%

# define export aoi
# exportAOI = ee.Feature(downloadGrids.toList(50).get(4))
# geePrint(exportAOI)
# exportAOI.geometry()
year 



# %%
### 
# Generate model based on year define in config 

# generate NAIP layer 
naipEE = prepNAIP(aoi=aoi1, year=year,windowSize=windowSize)
# geePrint(naipEE.bandNames())
# normal the naip data
# normalizedNAIP = normalize_by_maxes(img=naipEE, bandMaxes=bandMaxes)

# produce the SNIC object 
## filtering the image bands right away based on the single model output 
snicData = snicOutputs(naip = naipEE,
                       SNIC_SeedShape = SNIC_SeedShape, 
                       SNIC_SuperPixelSize = SNIC_SuperPixelSize, 
                       SNIC_Compactness = SNIC_Compactness, 
                       SNIC_Connectivity = SNIC_Connectivity,
                       # nativeScaleOfImage = nativeScaleOfImage, 
                       bandsToUse_Cluster = bandsToUse_Cluster).select(bandsToUse)
# apply the model and clip to aoi and reclass to unsigned 8bit image 
classifiedPixelsTrim = applyRFModel(imagery=snicData, bands=bandsToUse,classifier=rfPixelTrim).clip(aoi1).uint8()
# produce image for map 
demoImage = classifiedPixelsTrim #.clip(exportAOI)
# demoImage = classifiedPixelsTrim.clip(ee.Feature(downloadGrids.toList(50).get(10))).reproject(crs='EPSG:4326', scale=5)

geePrint(demoImage)


# %%


# %%
# Set visualization parameters.
vis_params = {
    'min': 0,
    'max': 1,
    'palette': ['#f5f7f710', '#10c9a1'],
}
# add features to the map
Map.addLayer(demoImage, vis_params, str(year) + ' model')


Map

# %%
export_params = {
'image': demoImage,
'description': str(aoiID) + "_" + str(year)  +"_cleanup",  # Task name (appears in GEE Tasks tab)
'folder': 'aagroforestry/imageCleanup/',  # Google Drive folder to export to
'scale': 1,  # Pixel resolution (in meters)
'region': aoi1.geometry(),  # Export area (image bounds)
# 'fileFormat': 'GeoTIFF',  # Output file format
# 'crs': naipa.projection(),       # Optional: Coordinate Reference System
# 'crsTransform': [30, 0, -2493045, 0, -30, 3310005], # Optional: CRS transform
'maxPixels': 1e13,        # Optional: Increase for large exports
}

# 3. Create and Start the Export Task
task = ee.batch.Export.image.toDrive(**export_params)

task.start()

# %%
#this will produce a asset 


# # export image to asset 
# task = ee.batch.Export.image.toAsset(
#   image = demoImage,
#   description = str(initGridID) + "_" + str(year) + "_36grid",
#   assetId = "projects/agroforestry2023/assets/"+ str(initGridID) + "_" + str(year) + "_36grid",
#   region=aoi1.geometry(),
#   scale=1,
#   crs= demoImage.projection(),
#   maxPixels = 1e13
# )
# task.start()

# %%
# # track the task 
# import time
# while task.active():
#   print('Polling for task (id: {}).'.format(task.id))
#   time.sleep(5)

# %%
geePrint(demoImage)


