import ee
import os
import geemap
import geopandas as gpd
import pandas as pd
from agroforestry.config import * 
from agroforestry.geeHelpers import *
from agroforestry.naipProcessing import *
from agroforestry.snicProcessing import *
from agroforestry.randomForest import *
from agroforestry.processUSDARef import *



# establish connection with ee account. might require some additional configuration based on local machine 
ee.Initialize()
# if issues see 0_develop training data for suggestions 

# import training dataset 
trainingData = gpd.read_file(filename="data/processed/trainingdataset_withClasses.geojson")
# print(type(trainingData))
# select the training class of interest and drop unnecessary columns
trainingSubset =  trainingData[trainingData.sampleStrat == "subgrid"]
# print(trainingSubset)
# convert to ee object
pointsEE = geemap.gdf_to_ee(gdf=trainingSubset)
# subset testing and training data 
training = pointsEE.filter(ee.Filter.gt('random', test_train_ratio))
testing = pointsEE.filter(ee.Filter.lte('random',test_train_ratio))
# traing the rf model 
rfCluster = trainRFModel(bands=bandsToUse_Cluster, inputFeature=training, nTrees=nTrees,setSeed=setSeed)
rfPixel = trainRFModel(bands=bandsToUse_Pixel, inputFeature=training, nTrees=nTrees,setSeed=setSeed)
## run validation using the testing set 
clusterValidation = testRFClassifier(classifier=rfCluster, testingData= testing)
pixelValidation = testRFClassifier(classifier=rfPixel, testingData= testing)
# cant print tuple with this function
#geePrint(clusterValidation)
#geePrint(pixelValidation)



# define the aoi
aoiID = initGridID # something to itorate over for now is defined based on the input training dataset 
# this becomes the AOI to used in the prepNAIP function. I'll need to edit it so that it converts the input data into a bbox 
gridSelect = grid.loc[grid.Unique_ID == aoiID]
# convert to a gee object 
aoi1 = geemap.gdf_to_ee(gridSelect)

# generate the USDA reference object 
usda1 = processUSDARef(aoiGrid = gridSelect, usdaRef=usdaRef)

# generate NAIP layer 
naipEE = prepNAIP(aoi=aoi1, year=year)

# normal the naip data
normalizedNAIP = normalize_by_maxes(img=naipEE, bandMaxes=bandMaxes)

# produce the SNIC object 
snicData = snicOutputs(naip = normalizedNAIP, SNIC_NeighborhoodSize = SNIC_NeighborhoodSize,
                       SNIC_SeedShape = SNIC_SeedShape, SNIC_SuperPixelSize = SNIC_SuperPixelSize, 
                       SNIC_Compactness = SNIC_Compactness, SNIC_Connectivity = SNIC_Connectivity,
                       nativeScaleOfImage = nativeScaleOfImage, bandsToUse_Cluster = bandsToUse_Cluster)
# geePrint(snicData.bandNames())

# apply the rf model to the cluster imagery 
classifiedClusters = applyRFModel(imagery=snicData, bands=bandsToUse_Cluster, classifier=rfCluster)
# geePrint(classifiedClusters)

# apply the rf model to the pixels 
classifiedPixels = applyRFModel(imagery=snicData, bands=bandsToUse_Pixel,classifier=rfPixel)

# generate the ensamble model 
combinedModels = classifiedPixels.add(classifiedClusters)
# reclass the image so it is a 0,1 value set 
from_list = [0, 1, 2]
# A corresponding list of replacement values (10 becomes 1, 20 becomes 2, etc).
to_list = [0, 0, 1]
combinedModelsReclass =  combinedModels.remap(from_list, to_list, bandName='classification')
geePrint(combinedModelsReclass)


# extact values to the testing  dataset
combinedModelsExtractedVals = combinedModelsReclass.sampleRegions(
    collection=testing, scale=1, geometries=False
)

# Generate a confusion matrix on the current classification 
combinedAccuracy = combinedModelsExtractedVals.errorMatrix("presence", "remapped")
geePrint(combinedAccuracy)
geePrint(combinedAccuracy.accuracy())



# # attempt to export the image 
out_dir = os.path.expanduser('~\Downloads')
cProj = combinedModelsReclass.reproject(crs="EPSG:3857")
# seems like the fishnet and the projected image are not lining up.
# fishnet = geemap.fishnet(data = geemap.image_bounds(cProj), cols=10, rows=10)
# tried generating on the image bound and getting an install error inthe `localtileserver` package
# geemap.download_ee_image_tiles(image = cProj, features=fishnet)
# export to geotiff
# geemap.ee_to_geotiff(cProj, output=out_dir,resolution=1) #issue with the gdal installation 
#export to numpy array 
# Image.sampleRectangle: Too many pixels in sample; must be <= 262144. Got 507180756.
n1 = geemap.ee_to_numpy(ee_object=cProj,region=aoi1)


##
# Total request size (749851530 bytes) must be less than or equal to 50331648 bytes.
geemap.ee_export_image(combinedModelsReclass, filename="data.tif", region=aoi1.geometry(), scale=1)