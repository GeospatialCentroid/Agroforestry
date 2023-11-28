import ee
import geemap
import geopandas as gpd
import pandas as pd
from agroforestry.config import * 
from agroforestry.geeHelpers import *
from agroforestry.naipProcessing import *
from agroforestry.snicProcessing import *
from agroforestry.randomForest import *



# establish connection with ee account. might require some additional configuration based on local machine 
ee.Initialize()
# if issues see 0_develop training data for suggestions 

# import training dataset 
trainingData = gpd.read_file(filename="data/processed/trainingdataset_withClasses.geojson")
# print(type(trainingData))
# select the training class of interest and drop unnecessary columns
trainingSubset =  trainingData[trainingData.sampleStrat == "original"]
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




# define the aoi
aoiID = 'X12-695' # something to itorate over 
# this becomes the AOI to used in the prepNAIP function. I'll need to edit it so that it converts the input data into a bbox 
gridSelect = grid.loc[grid.Unique_ID == aoiID]
# convert to a gee object 
aoi1 = geemap.gdf_to_ee(gridSelect)

# generate random points to used as the validation set
randomPoints = ee.FeatureCollection.randomPoints(
    region=aoi1, points=500, seed=setSeed)
# geePrint(randomPoints)

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
# this hold all the data for bands used in the modeling process, need to grab a presenec absense fromt he 
# model products and rename to presence, then I can get validation data from the new imagery 
testData = snicData.sampleRegions(collection= randomPoints,
                                scale= 1,
                                geometries= True)

# # apply the rf model to the cluster imagery 
classifiedClusters = applyRFModel(imagery=snicData, bands=bandsToUse_Cluster, classifier=rfCluster)
# # geePrint(classifiedClusters)


# extract the values to the test data -- build into a function 
## need to rename the value to presence to work in the existing function 
classC_rename = classifiedClusters.rename('presence')
# geePrint(classC_rename.bandNames())
stratifedTest = classC_rename.stratifiedSample(numPoints = 500, seed = setSeed) 
geePrint(stratifedTest)

# testDataCluster = classC_rename.sampleRegions(collection = testData,
#                                                    scale = 1)
# # geePrint(testDataCluster)

# # next run the class testRFClassifier
# test1 = testRFClassifier(classifier=rfCluster,testingData=testDataCluster)
# geePrint(test1)


# # run validation against the random points 
# clusterTestVals = classifiedClusters.sampleRegions(collection= randomPoints,
#                                 scale= 1,
#                                 geometries= False);    
# # geePrint(clusterTest)
# clusterTestResults = testRFClassifier(classifier=rfCluster,testingData=clusterTestVals)
# geePrint(clusterTestResults)
# apply the rf model to the pixel base classification 
# classifedPixels = applyRFModel(imagery=snicData, bands=bandsToUse_Pixel, classifier=rfPixel)
# geePrint(classifedPixels)



# # create a dataframe to store the parameters changed and the classification accuracies 
# df = pd.DataFrame(columns=['Column 1', 'Column 2', 'Column 3'])


# # generate the ensamble model 
# # while this is the final output I can acutally validate it because I don't have a specific classified for the output. 
# # combinedModels = classifed_pixels.add(classified_clusters)
# # geePrint(combinedModels)