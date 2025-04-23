####
# breaking away from the primary workflow here to tackle single model area reruns using the harmization method that gavin developed
###

import ee
import geemap
import geopandas as gpd
import pandas as pd
import numpy as np
import random

# ee.Authenticate(auth_mode = 'notebook')
ee.Initialize(project='agroforestry2023')
# from agroforestry.config import * 
from agroforestry.geeHelpers import *
from agroforestry.naipProcessing import *
from agroforestry.snicProcessing import *
from agroforestry.randomForest import *
from agroforestry.exportFunctions import *
from agroforestry.histMatch import *

# try:
#         ee.Initialize(project='agroforestry2023')
# except Exception as e:
#         ee.Authenticate(auth_mode='notebook')        
#         ee.Initialize()
# SNIC based parametes 
## Defining the Seed Grid
# The superpixel seed location spacing, in pixels. Has a big effect on the total number of clusters generated
SNIC_SuperPixelSize= 30
SNIC_SuperPixelSize_range = np.arange(3, 100, 5)# this is the parameter with the most number of options   
# Either 'square' or 'hex'. hex has a more variable position set across the landscape
SNIC_SeedShape='square'
SNIC_SeedShape_range = ["hex","square"]

## snic algorythem changes directly
# Larger values cause clusters to be more compact (square/hexagonal). Anything over 1 seems to cause this. 
# Setting this to 0 disables spatial distance weighting.
SNIC_Compactness=0.75
SNIC_Compactness_range = np.arange(0.0, 1.4, 0.2)
# Connectivity. Either 4 or 8. Did not seem to effect to much... 
SNIC_Connectivity=4
SNIC_Connectivity_range = [4,8]



# read in grid object 
Grids = gpd.read_file("data/processed/griddedFeatures/twelve_mi_grid_uid.gpkg")

# # 2010 models to rerun 
models10 = ["X12-83", "X12-83", "X12-83", "X12-83", "X12-83", "X12-83", "X12-83", "X12-150",
 "X12-594", "X12-594", "X12-594", "X12-594", "X12-594", "X12-594",  "X12-615",
 "X12-594"]
ranGrid10 = [ "X12-1","X12-2","X12-3","X12-4","X12-5","X12-6", 
"X12-7","X12-336", "X12-414", "X12-415", "X12-592", "X12-637",
"X12-682","X12-725","X12-740","X12-766"]
# # 2016 models to rerun 
models16 = ["X12-150", "X12-594", "X12-594", "X12-594","X12-594",
 "X12-594","X12-594", "X12-615","X12-615"  ]
ranGrid16 = ["X12-336","X12-414","X12-415","X12-592","X12-637",
"X12-682","X12-725", "X12-740", "X12-766"]
# # 2020 models to rerun 
models20 = ["X12-150", "X12-615"]
ranGrid20 = ["X12-336","X12-740"]



# define standard variable set 
bandsToUse = ["contrast_n_mean", "entropy_n_mean", "entropy_n", 
"entropy_g_mean","nd_mean_neighborhood","contrast_n",
"entropy_g","nd_mean","contrast_g_mean","contrast_g"] 

# Set the seed value
random.seed(42)
# set unique parameters 
year = 2016
models = models16
ranGrid = ranGrid16
for i in range(len(ranGrid)):
        # model grid
        modelGrid =  models[i]  
        # define gird to apply the mode 
        applyGrid = ranGrid[i]
        # define file location 
        processedData = 'data/processed/'+modelGrid
        # select grids to generate spatial object 
        mGrid =  Grids[Grids['Unique_ID'] == modelGrid]
        aGrid =  Grids[Grids['Unique_ID'] == applyGrid]
        # convert to a gee object 
        mAOI = geemap.gdf_to_ee(mGrid)
        aAOI = geemap.gdf_to_ee(aGrid)

        # define training data
        trainingData = gpd.read_file(filename="data/processed/" +
        str(modelGrid) +"/"+ "agroforestrySamplingData_"+str(year)+".geojson") # initGridID defined int he config file

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


        ndvia = naipTrain.normalizedDifference(["N","R"])

        # generate GLCM
        glcm_ga = naipTrain.select('G').glcmTexture(size = windowSize).select(['G_savg','G_contrast','G_ent'],["savg_g", "contrast_g", "entropy_g"])
        glcm_na = naipTrain.select('N').glcmTexture(size= windowSize).select(['N_savg','N_contrast','N_ent'],["savg_n", "contrast_n", "entropy_n"])
        # add to naip 
        naip2a = naipTrain.addBands(glcm_ga).addBands(glcm_na)

        # average and standard deviation NDVI
        ndvi_sd_neighborhooda =  ndvia.select('nd').reduceNeighborhood(reducer = ee.Reducer.stdDev(),kernel = ee.Kernel.circle(windowSize)).rename(["nd_sd_neighborhood"])
        ndvi_mean_neighborhooda =  ndvia.select('nd').reduceNeighborhood(reducer= ee.Reducer.mean(),  kernel= ee.Kernel.circle(windowSize)).rename(["nd_mean_neighborhood"])

        # Bind ndvi after the glcm processall the bands together 
        naipa = naipTrain.addBands(ndvia).addBands(ndvi_sd_neighborhooda).addBands(ndvi_mean_neighborhooda)

        bandsToUse_Cluster = ['R_mean', 'G_mean','B_mean', "N_mean", "nd_mean",'savg_g_mean', 'contrast_g_mean', 'entropy_g_mean', 'savg_n_mean',
                        'contrast_n_mean', 'entropy_n_mean']
        # apply snic classified 
        naip2  = snicOutputs(naip = naipa,
                                SNIC_SeedShape = SNIC_SeedShape, 
                                SNIC_SuperPixelSize = SNIC_SuperPixelSize, 
                                SNIC_Compactness = SNIC_Compactness, 
                                SNIC_Connectivity = SNIC_Connectivity,
                                # nativeScaleOfImage = nativeScaleOfImage, 
                                bandsToUse_Cluster = bandsToUse_Cluster).select(bandsToUse)

        classifiedPixelsTrim = applyRFModel(imagery=naip2, bands=bandsToUse,classifier=rfPixelTrim).clip(aAOI).uint8()

        # export image to asset 
        # task = ee.batch.Export.image.toAsset(
        #         image = classifiedPixelsTrim,
        #         description = str(applyGrid) + str(year),
        #         assetId = "projects/agroforestry2023/assets/"+ str(applyGrid) + 
        #         "_"+ str(year)+ "_042025Runs",
        #         region= aAOI.geometry(),
        #         scale=1,
        #         crs= naipa.projection(),
        #         maxPixels = 1e13
        # )
        # task.start()
        # # export image to drive 
        # task = ee.batch.Export.image.toAsset(
        #         image = classifiedPixelsTrim,
        #         description = str(applyGrid) +"_"+ str(year),
        #         assetId = "projects/agroforestry2023/assets/"+ str(applyGrid) + 
        #         "_"+ str(year)+ "_042025Runs",
        #         region= aAOI.geometry(),
        #         scale=1,
        #         crs= naipa.projection(),
        #         maxPixels = 1e13
        # )

       # 2. Define Export Parameters
        export_params = {
        'image': classifiedPixelsTrim,
        'description': str(applyGrid) +"_"+ str(year) +"_harmoizedOutputs",  # Task name (appears in GEE Tasks tab)
        'folder': 'agroforestry',  # Google Drive folder to export to
        'scale': 1,  # Pixel resolution (in meters)
        'region': aAOI.geometry(),  # Export area (image bounds)
        # 'fileFormat': 'GeoTIFF',  # Output file format
        'crs': naipa.projection(),       # Optional: Coordinate Reference System
        # 'crsTransform': [30, 0, -2493045, 0, -30, 3310005], # Optional: CRS transform
        'maxPixels': 1e13,        # Optional: Increase for large exports
        }

        # 3. Create and Start the Export Task
        task = ee.batch.Export.image.toDrive(**export_params)
        task.start()
