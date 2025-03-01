####
# breaking away from the primary workflow here to tackle single model area reruns using the harmization method that gavin developed
###

import ee
import geemap
import geopandas as gpd
import pandas as pd
import numpy as np

ee.Initialize(project='agroforestry2023')
# from agroforestry.config import * 
from agroforestry.geeHelpers import *
from agroforestry.naipProcessing import *
from agroforestry.snicProcessing import *
from agroforestry.randomForest import *
from agroforestry.exportFunctions import *
from agroforestry.histMatch import *

# ee.Authenticate()        


# try:
#         ee.Initialize(project='agroforestry2023')
# except Exception as e:
#         ee.Authenticate(auth_mode='notebook')        
#         ee.Initialize()

# read in grid object 
Grids = gpd.read_file("data/processed/griddedFeatures/twelve_mi_grid_uid.gpkg")

# define model grid 
modelGrid =  "X12-519" 

# define gird to apply the mode 
applyGrid = "X12-608"

# define year 
year = 2010

# define standard variable set 
bandsToUse = ["contrast_n_mean", "entropy_n_mean", "entropy_n", "entropy_g_mean","nd_mean_neighborhood","contrast_n","entropy_g","nd_mean","contrast_g_mean","contrast_g"] 

# define file location 
processedData = 'data/processed/'+modelGrid

# select grids to generate spatial object 
mGrid =  Grids[Grids['Unique_ID'] == modelGrid]
aGrid =  Grids[Grids['Unique_ID'] == applyGrid]

# convert to a gee object 
mAOI = geemap.gdf_to_ee(mGrid)
aAOI = geemap.gdf_to_ee(aGrid)

# define training data
trainingData = gpd.read_file(filename="data/processed/" + str(modelGrid) +"/"+ "agroforestrySamplingData_"+str(year)+".geojson") # initGridID defined int he config file

# divide the data into test train spilts
trainingData = trainingData.sample(frac = 1)
# get rows 
total_rows = trainingData.shape[0]
# get train size 
test_train_ratio = 0.8
train_size = int(total_rows*test_train_ratio)

# Split data into test and train
train = trainingData[0:train_size]
test = trainingData[train_size:]
# define the GEE objects
training = geemap.gdf_to_ee(gdf=train)
testing = geemap.gdf_to_ee(gdf=test)

# train model
nTrees = 10
nTrees_range = np.arange(2, 20, 2)
setSeed = 5

# window size for average NDVI and glcm 
windowSize = 8
rfPixelTrim = trainRFModel(bands=bandsToUse,  inputFeature=training, nTrees=nTrees,setSeed=setSeed )
## run validation using the testing set 
pixelValidationTrim = testRFClassifier(classifier=rfPixelTrim, testingData= testing)


# naip processing for model grid --- no normalization at this point so we can call from the existing function 
# grab naip for the year of interest, filter, mask, mosaic to a single image
naipTrain = prepNAIP(aoi=mAOI,windowSize=windowSize, year=year)
geePrint(naipTrain)
#####

# getNAIP(year=year, gridArea=mAOI)


#### model grids that need to be reclassified 
# integrate Gavins histogram matching work. Start byt 
naip1 = matchSelf(gridArea= aAOI, 
                  year = year)
geePrint(naip1)


# Generate NDVI 
ndvia = naip1.normalizedDifference(["N","R"])

# generate GLCM
glcm_ga = naip1.select('G').glcmTexture(size = windowSize).select(['G_savg','G_contrast','G_ent'],["savg_g", "contrast_g", "entropy_g"])
glcm_na = naip1.select('N').glcmTexture(size= windowSize).select(['N_savg','N_contrast','N_ent'],["savg_n", "contrast_n", "entropy_n"])
# add to naip 
naip2a = naip1.addBands(glcm_ga).addBands(glcm_na)

# average and standard deviation NDVI
ndvi_sd_neighborhooda =  ndvia.select('nd').reduceNeighborhood(reducer = ee.Reducer.stdDev(),kernel = ee.Kernel.circle(windowSize)).rename(["nd_sd_neighborhood"])
ndvi_mean_neighborhooda =  ndvia.select('nd').reduceNeighborhood(reducer= ee.Reducer.mean(),  kernel= ee.Kernel.circle(windowSize)).rename(["nd_mean_neighborhood"])

# Bind ndvi after the glcm processall the bands together 
naipa = naip1.addBands(ndvia).addBands(ndvi_sd_neighborhooda).addBands(ndvi_mean_neighborhooda)

# apply the model 
classifiedPixelsTrim = applyRFModel(imagery=naipa, bands=bandsToUse,classifier=rfPixelTrim).clip(aAOI).uint8()

?    # export image to asset 
task = ee.batch.Export.image.toAsset(
        image = classifiedPixelsTrim,
        description = str(applyGrid) + "_histNorm_self",
        assetId = "projects/agroforestry2023/assets/"+ str(applyGrid) + "_histNorm_self",
        region=aoi1.geometry(),
        scale=1,
        crs= demoImage.projection(),
        maxPixels = 1e13
)
task.start()

# for i in years: 
#     # define file location 
#     processedData = 'data/processed/'+initGridID
#     neighborGrid = pd.read_csv(processedData + "/neighborGrids.csv")
#     grid36 = neighborGrid[neighborGrid['poisition'].isin([1,2,3,4])]
#     # set aoi for the gee objects 
#     aoiID = initGridID
#     #Define bands to use -- setting manually 
#     bandsToUse = vsurfNoCor
#     ### this was used to generate the _b versions of the models 
#     # bandsToUse = ["contrast_n_mean", "entropy_n_mean", "entropy_n", "entropy_g_mean","nd_mean_neighborhood","contrast_n","entropy_g","nd_mean","contrast_g_mean","contrast_g"] 
#     # select multiple grids level 
#     gridSelect =  grid.loc[grid.Unique_ID.isin(grid36.Unique_ID)].dissolve()
#     # convert to a gee object 
#     aoi1 = geemap.gdf_to_ee(gridSelect)
#     # import training dataset 
#     trainingData = gpd.read_file(filename="data/processed/" + str(initGridID) +"/"+ "agroforestrySamplingData_"+str(i)+".geojson") # initGridID defined int he config file
#     # divide the data into test train spilts 
#     trainingData = trainingData.sample(frac = 1)
#     # get rows 
#     total_rows = trainingData.shape[0]
#     # get train size 
#     train_size = int(total_rows*test_train_ratio)

#     # Split data into test and train
#     train = trainingData[0:train_size]
#     test = trainingData[train_size:]
#     # define the GEE objects
#     training = geemap.gdf_to_ee(gdf=train)
#     testing = geemap.gdf_to_ee(gdf=test)
#     # train model
#     rfPixelTrim = trainRFModel(bands=bandsToUse,  inputFeature=training, nTrees=nTrees,setSeed=setSeed )
#     ## run validation using the testing set 
#     pixelValidationTrim = testRFClassifier(classifier=rfPixelTrim, testingData= testing)

#     # Generate model based on year define in config 
#     # generate NAIP layer 
#     naipEE = prepNAIP(aoi=aoi1, year=i,windowSize=windowSize)
#     ##


#     # geePrint(naipEE.bandNames())
#     # normal the naip data
#     # normalizedNAIP = normalize_by_maxes(img=naipEE, bandMaxes=bandMaxes)
#     # produce the SNIC object 
#     ## filtering the image bands right away based on the single model output 
#     snicData = snicOutputs(naip = naipEE,
#                         SNIC_SeedShape = SNIC_SeedShape, 
#                         SNIC_SuperPixelSize = SNIC_SuperPixelSize, 
#                         SNIC_Compactness = SNIC_Compactness, 
#                         SNIC_Connectivity = SNIC_Connectivity,
#                         # nativeScaleOfImage = nativeScaleOfImage, 
#                         bandsToUse_Cluster = bandsToUse_Cluster).select(bandsToUse)
#     # apply the model and clip to aoi and reclass to unsigned 8bit image 
#     classifiedPixelsTrim = applyRFModel(imagery=snicData, bands=bandsToUse,classifier=rfPixelTrim).clip(aoi1).uint8()
#     demoImage = classifiedPixelsTrim #.clip(exportAOI)
#     print("projects/agroforestry2023/assets/"+ str(initGridID) + "_" + str(i) + "_36grid")
#     # export image to asset 
#     task = ee.batch.Export.image.toAsset(
#         image = demoImage,
#         description = str(initGridID) + "_" + str(i) + "_b_36grid",
#         assetId = "projects/agroforestry2023/assets/"+ str(initGridID) + "_b_" + str(i) + "_36grid",
#         region=aoi1.geometry(),
#         scale=1,
#         crs= demoImage.projection(),
#         maxPixels = 1e13
#     )
#     task.start()

