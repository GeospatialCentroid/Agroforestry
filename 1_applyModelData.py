import ee
import geemap
import geopandas as gpd
import pandas as pd
import numpy as np
from agroforestry.config import * 
from agroforestry.geeHelpers import *
from agroforestry.naipProcessing import *
from agroforestry.snicProcessing import *
from agroforestry.randomForest import *
from agroforestry.exportFunctions import *

try:
        ee.Initialize()
except Exception as e:
        ee.Authenticate()
        ee.Initialize()

# Set gridID and itorate over the years 
# define initial sub grid 

#2016 models to rerun 
models = ["X12-602","X12-99","X12-32","X12-91", "X12-115","X12-281","X12-318","X12-278"]
completed2016Grids = ["X12-602","X12-99","X12-32","X12-91", "X12-115","X12-281","X12-318","X12-278"]
# 2010 models to rerun 
models = ["X12-642","X12-519","X12-633"]
ranGrid = []
# 2020 models to rerun 
models = ["X12-594","X12-183","X12-300","X12-150"]
ranGrid = []


initGridID = 'X12-642' # "X12-642" #     " 
years = [2010,2016,2020]
for i in years: 
        # define file location 
    processedData = 'data/processed/'+initGridID
    neighborGrid = pd.read_csv(processedData + "/neighborGrids.csv")
    grid36 = neighborGrid[neighborGrid['poisition'].isin([1,2,3,4])]
    # set aoi for the gee objects 
    aoiID = initGridID
    #Define bands to use -- setting manually 
    bandsToUse = ["contrast_n_mean", "entropy_n_mean", "entropy_n", "entropy_g_mean","nd_mean_neighborhood","contrast_n",
                "entropy_g","nd_mean","contrast_g_mean","contrast_g"] 
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