####
# breaking away from the primary workflow here to tackle single model area reruns using the harmization method that gavin developed
###

import ee
import geemap
import geopandas as gpd
import pandas as pd
import numpy as np
# from agroforestry.config import * 
from agroforestry.geeHelpers import *
from agroforestry.naipProcessing import *
from agroforestry.snicProcessing import *
from agroforestry.randomForest import *
from agroforestry.exportFunctions import *

try:
        ee.Initialize(project='agroforestry2023')
except Exception as e:
        ee.Authenticate(auth_mode='notebook')        
        ee.Initialize()

# read in grid object 
grid = gpd.read_file("data/processed/griddedFeatures/twelve_mi_grid_uid.gpkg")

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
mGrid =  grid[grid['Unique_ID'] == modelGrid]
aGrid =  grid[grid['Unique_ID'] == applyGrid]

# convert to a gee object 
mAOI = geemap.gdf_to_ee(mGrid)
aAOI = geemap.gdf_to_ee(aGrid)

# define training data
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

# train model
rfPixelTrim = trainRFModel(bands=bandsToUse,  inputFeature=training, nTrees=nTrees,setSeed=setSeed )
## run validation using the testing set 
pixelValidationTrim = testRFClassifier(classifier=rfPixelTrim, testingData= testing)


# naip processing for model grid --- no normalization at this point 
# grab naip for the year of interest, filter, mask, mosaic to a single image
naip1 = geemap.get_annual_NAIP(year).filterBounds(aoi).mosaic() 
# Generate NDVI 
ndvi = naip1.normalizedDifference(["N","R"])
# generate GLCM
glcm_g = naip1.select('G').glcmTexture(size = windowSize).select(['G_savg','G_contrast','G_ent'],["savg_g", "contrast_g", "entropy_g"])
glcm_n = naip1.select('N').glcmTexture(size= windowSize).select(['N_savg','N_contrast','N_ent'],["savg_n", "contrast_n", "entropy_n"])
# add to naip 
naip2 = naip1.addBands(glcm_g).addBands(glcm_n)

# average and standard deviation NDVI
ndvi_sd_neighborhood =  ndvi.select('nd').reduceNeighborhood(reducer = ee.Reducer.stdDev(),kernel = ee.Kernel.circle(windowSize)).rename(["nd_sd_neighborhood"])
ndvi_mean_neighborhood =  ndvi.select('nd').reduceNeighborhood(reducer= ee.Reducer.mean(),  kernel= ee.Kernel.circle(windowSize)).rename(["nd_mean_neighborhood"])

# Bind ndvi after the glcm processall the bands together 
naip = naip2.addBands(ndvi).addBands(ndvi_sd_neighborhood).addBands(ndvi_mean_neighborhood)

#####
# gather NAIP data required for apply model area 
# grab naip for the year of interest, filter, mask, mosaic to a single image
naip1a = geemap.get_annual_NAIP(year).filterBounds(aoi).mosaic() 

#
# integrate Gavins histogram matching work. Start byt 

# Generate NDVI 
ndvia = naip1a.normalizedDifference(["N","R"])
# generate GLCM
glcm_ga = naip1a.select('G').glcmTexture(size = windowSize).select(['G_savg','G_contrast','G_ent'],["savg_g", "contrast_g", "entropy_g"])
glcm_na = naip1a.select('N').glcmTexture(size= windowSize).select(['N_savg','N_contrast','N_ent'],["savg_n", "contrast_n", "entropy_n"])
# add to naip 
naip2a = naip1a.addBands(glcm_g).addBands(glcm_n)

# average and standard deviation NDVI
ndvi_sd_neighborhooda =  ndvia.select('nd').reduceNeighborhood(reducer = ee.Reducer.stdDev(),kernel = ee.Kernel.circle(windowSize)).rename(["nd_sd_neighborhood"])
ndvi_mean_neighborhooda =  ndvia.select('nd').reduceNeighborhood(reducer= ee.Reducer.mean(),  kernel= ee.Kernel.circle(windowSize)).rename(["nd_mean_neighborhood"])

# Bind ndvi after the glcm processall the bands together 
naipa = naip2a.addBands(ndvia).addBands(ndvi_sd_neighborhooda).addBands(ndvi_mean_neighborhooda)















for i in years: 
    # define file location 
    processedData = 'data/processed/'+initGridID
    neighborGrid = pd.read_csv(processedData + "/neighborGrids.csv")
    grid36 = neighborGrid[neighborGrid['poisition'].isin([1,2,3,4])]
    # set aoi for the gee objects 
    aoiID = initGridID
    #Define bands to use -- setting manually 
    bandsToUse = vsurfNoCor
    ### this was used to generate the _b versions of the models 
    # bandsToUse = ["contrast_n_mean", "entropy_n_mean", "entropy_n", "entropy_g_mean","nd_mean_neighborhood","contrast_n","entropy_g","nd_mean","contrast_g_mean","contrast_g"] 
    # select multiple grids level 
    gridSelect =  grid.loc[grid.Unique_ID.isin(grid36.Unique_ID)].dissolve()
    # convert to a gee object 
    aoi1 = geemap.gdf_to_ee(gridSelect)
    # import training dataset 
    trainingData = gpd.read_file(filename="data/processed/" + str(initGridID) +"/"+ "agroforestrySamplingData_"+str(i)+".geojson") # initGridID defined int he config file
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
    # train model
    rfPixelTrim = trainRFModel(bands=bandsToUse,  inputFeature=training, nTrees=nTrees,setSeed=setSeed )
    ## run validation using the testing set 
    pixelValidationTrim = testRFClassifier(classifier=rfPixelTrim, testingData= testing)

    # Generate model based on year define in config 
    # generate NAIP layer 
    naipEE = prepNAIP(aoi=aoi1, year=i,windowSize=windowSize)
    ##


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
    demoImage = classifiedPixelsTrim #.clip(exportAOI)
    print("projects/agroforestry2023/assets/"+ str(initGridID) + "_" + str(i) + "_36grid")
    # export image to asset 
    task = ee.batch.Export.image.toAsset(
        image = demoImage,
        description = str(initGridID) + "_" + str(i) + "_b_36grid",
        assetId = "projects/agroforestry2023/assets/"+ str(initGridID) + "_b_" + str(i) + "_36grid",
        region=aoi1.geometry(),
        scale=1,
        crs= demoImage.projection(),
        maxPixels = 1e13
    )
    task.start()

