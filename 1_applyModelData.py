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
## this is still a vector product


# generate NAIP layer 
naipEE = prepNAIP(aoi=aoi1, year=year)

# normal the naip data
normalizedNAIP = normalize_by_maxes(img=naipEE, bandMaxes=bandMaxes)

# produce the SNIC object 
snicData = snicOutputs(naip = normalizedNAIP,
                       SNIC_SeedShape = SNIC_SeedShape, 
                       SNIC_SuperPixelSize = SNIC_SuperPixelSize, 
                       SNIC_Compactness = SNIC_Compactness, 
                       SNIC_Connectivity = SNIC_Connectivity,
                       # nativeScaleOfImage = nativeScaleOfImage, 
                       bandsToUse_Cluster = bandsToUse_Cluster)
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


## add a condtional statement here to determine if the file should be downloaded or not. 
## also improve the 
if download
# downloading the data 
geemap.ee_to_geotiff(combinedModelsReclass, output="test.tif")
fishnet = geemap.fishnet(aoi1, h_interval=1000, v_interval=1000)
## 
test1 = combinedModelsReclass.clip(aoi1)
## exports at 10 meters this works!  
geemap.ee_export_image(
    test1, filename="data/processed/appliedModels/imagery/" + initGridID+ "_"+ year+ ".tif",
      scale=10,
        region=aoi1.geometry()
)
# doing comparison at 10m


## export at 1 meter --- needs to be 14 times smaller 
# geemap.ee_export_image(
#     test1, filename="tests1.tif", scale=5, region=aoi1.geometry(), file_per_band=False
#)

# save model parameters to a spreadsheet 1
# create a dictionary so we can export information 
dic2 = ee.Dictionary({
    "gridID" : initGridID,
    "naipYear" : year,
    "totalNumberTest" :  testing.size(),
    "SNIC_SuperPixelSize" : SNIC_SuperPixelSize, 
    "SNIC_Compactness" : SNIC_Compactness,
    "SNIC_Connectivity": SNIC_Connectivity, 
    "SNIC_SeedShape": SNIC_SeedShape,
    "nTrees": nTrees,
    'allValues' : combinedAccuracy.array(),
    'overallAccuracy' : combinedAccuracy.accuracy()})


geemap.dict_to_csv(dic2, out_csv= "data/processed/appliedModels/" + initGridID+ "_" + str(year) + ".csv")

