import ee
ee.Initialize(project='agroforestry2023')

import os, time
from datetime import datetime
import geemap
import geopandas as gpd
import pandas as pd
import numpy as np
from agroforestry1.snicProcessing import *
from agroforestry1.randomForest import *
from agroforestry1.histMatch import *

###############################################################################################################
year = 2010
target_grids = ['X12-698']
reference_grids = ['X12-602']

grid = gpd.read_file('data/processed/griddedFeatures/twelve_mi_grid_uid.gpkg')
test_train_ratio = 0.8
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

# RandomForest parameters
### need to do a little reading to understand what is really worth testing here. 0
nTrees = 10
nTrees_range = np.arange(2, 20, 2)
setSeed = 5

# window size for average NDVI and glcm
windowSize = 8

# these are hard coded parameters come back to them if you start
# altering the number of input bands to the SNIC function
# selection layers to use in the pixel based and cluster based modeling process
bandsToUse_Pixel = ['R_mean', 'G_mean', 'B_mean', 'N_mean', 'nd_mean', 'savg_g_mean', 'contrast_g_mean', 'entropy_g_mean',
                     'savg_n_mean', 'contrast_n_mean', 'entropy_n_mean', 'R', 'G', 'B', 'N', 'savg_g', 'contrast_g', 'entropy_g',
                       'savg_n', 'contrast_n', 'entropy_n', 'nd', 'nd_sd_neighborhood', 'nd_mean_neighborhood']
## only bands that are based on mean area measures
bandsToUse_Cluster = ['R_mean', 'G_mean','B_mean', "N_mean", "nd_mean",'savg_g_mean', 'contrast_g_mean', 'entropy_g_mean', 'savg_n_mean',
                       'contrast_n_mean', 'entropy_n_mean']

###############################################################################################################

def prepEEimage(input_naip, windowSize):
    # input_naip = ee.Image(image_path)#geemap.get_annual_NAIP(year).filterBounds(aoi).mosaic()
    # Generate NDVI
    ndvi = input_naip.normalizedDifference(["N","R"])
    # generate GLCM
    glcm_g = input_naip.select('G').glcmTexture(size = windowSize).select(['G_savg','G_contrast','G_ent'],["savg_g", "contrast_g", "entropy_g"])
    glcm_n = input_naip.select('N').glcmTexture(size= windowSize).select(['N_savg','N_contrast','N_ent'],["savg_n", "contrast_n", "entropy_n"])
    # add to naip
    naip2 = input_naip.addBands(glcm_g).addBands(glcm_n)
    # average and standard deviation NDVI
    ndvi_sd_neighborhood =  ndvi.select('nd').reduceNeighborhood(reducer = ee.Reducer.stdDev(),kernel = ee.Kernel.circle(windowSize)).rename(["nd_sd_neighborhood"])
    ndvi_mean_neighborhood =  ndvi.select('nd').reduceNeighborhood(reducer= ee.Reducer.mean(),  kernel= ee.Kernel.circle(windowSize)).rename(["nd_mean_neighborhood"])
    # Bind ndvi after the glcm processall the bands together
    naip = naip2.addBands(ndvi).addBands(ndvi_sd_neighborhood).addBands(ndvi_mean_neighborhood)
    # export a ee object of the NAIP imagery
    return naip

###############################################################################################################

human_readable = datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d %H:%M:%S')
print('Creating classified agroforestry maps using grid-specific features:')
print(f'Execution started at at {human_readable}')
print(f'Processing files for year {year}...')
grids = gpd.read_file(f'data/products/modelGrids_{year}.gpkg')

for (tar_grid, ref_grid) in list(zip(target_grids, reference_grids)):
    print(f'Processing started for target (mapped) grid {tar_grid} and reference (classifier) grid {ref_grid}...')
    # define file location
    processedData = 'data/processed/'+ref_grid
    if not os.path.exists(processedData):
        print(f'Folder for grid {ref_grid} does not exist.')
        continue
    grid_to_map = grids.loc[grid.Unique_ID == ref_grid]
    classifierGrid = geemap.gdf_to_ee(grid_to_map)
    #Define bands to use
    variableSelection = processedData + "/variableSelection" + str(year) + ".csv"
    selectedVariables = pd.read_csv(variableSelection)
    # vsurf select variables top 10
    vsurfWithCor = selectedVariables.iloc[:10]["varNames"].tolist()
    # vsurf select variables with removed correlations
    vsurfNoCor = selectedVariables.query('includeInFinal == True').iloc[:10]["varNames"].tolist()
    bandsToUse = vsurfNoCor

    # import training dataset
    trainingData = gpd.read_file(filename=processedData +"/"+ "agroforestrySamplingData_"+str(year)+".geojson")
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

    ################################ generate map for self-harmonized image ###################################

    try:
        grid_to_map = grids.loc[grid.Unique_ID == tar_grid]
        gridArea = geemap.gdf_to_ee(grid_to_map)
        matched_naip = matchSelf(gridArea=gridArea, year=year)
        description = 'self_harmonized_naip_' + str(tar_grid) + '_' + str(year)
        print(' -> Saving to Google Drive: ' + description)
        task = ee.batch.Export.image.toDrive(
            image=matched_naip,
            description=description,
            folder=str(year),
            region=gridArea.geometry(),
            scale=1,
            crs= matched_naip.projection(),
            maxPixels=1e13
        )
        task.start()

        prepared_naip = prepEEimage(matched_naip, windowSize)
        # naipEE = prepEEimage(base_gee_asset1.format(tar_grid=tar_grid, year=year), windowSize)
        ## filtering the image bands right away based on the single model output
        snicData = snicOutputs(naip=prepared_naip,
                               SNIC_SeedShape=SNIC_SeedShape,
                               SNIC_SuperPixelSize=SNIC_SuperPixelSize,
                               SNIC_Compactness=SNIC_Compactness,
                               SNIC_Connectivity=SNIC_Connectivity,
                               # nativeScaleOfImage=nativeScaleOfImage,
                               bandsToUse_Cluster=bandsToUse_Cluster).select(bandsToUse)
        # apply the model and clip to aoi and reclass to unsigned 8bit image
        classifiedPixelsTrim = applyRFModel(imagery=snicData, bands=bandsToUse,classifier=rfPixelTrim).uint8()
        # print(f'Exporting classified maps for self_harmonized cell {tar_grid} using reference cell {ref_grid}')
        description = 'self_harmonized_map_' + str(tar_grid) + "_using_" + ref_grid + '_' + str(year)
        print(' -> Saving to Google Drive: ' + description)
        # export image to asset
        task = ee.batch.Export.image.toDrive(
            image=classifiedPixelsTrim,
            description=description,
            folder=str(year),
            region=gridArea.geometry(),
            scale=1,
            crs= classifiedPixelsTrim.projection(),
            maxPixels=1e13
        )
        task.start()
        while (task.status()['state'] not in ['COMPLETED', 'FAILED']):
            time.sleep(30)
        human_readable = datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d %H:%M:%S')
        print(f' -> Export finished at {human_readable}')
    except:
        # print('failed to process asset '+base_gee_asset1.format(tar_grid=tar_grid, year=year))
        print(f'failed to harmonize grid {tar_grid}.')

    ################################ generate map for ref-harmonized image ###################################

    try:
        ref_grid_to_map = grids.loc[grid.Unique_ID == ref_grid]
        ref_gridArea = geemap.gdf_to_ee(ref_grid_to_map)
        ref_naip = getNAIP(gridArea=ref_gridArea, year=year)

        tar_grid_to_map = grids.loc[grid.Unique_ID == tar_grid]
        tar_gridArea = geemap.gdf_to_ee(tar_grid_to_map)
        matched_naip = matchGrid(gridIDs=[tar_grid], referenceImage=ref_naip, year=year)

        description = 'ref_harmonized_naip_' + str(tar_grid) + "_using_" + ref_grid + '_' + str(year)
        print(' -> Saving to Google Drive: ' + description)
        # export image to asset
        task = ee.batch.Export.image.toDrive(
            image=matched_naip,
            description=description,
            folder=str(year),
            region=tar_gridArea.geometry(),
            scale=1,
            crs=matched_naip.projection(),
            maxPixels=1e13
        )
        task.start()

        prepared_naip = prepEEimage(matched_naip, windowSize)
        # naipEE = prepEEimage(base_gee_asset2.format(tar_grid=tar_grid, ref_grid=ref_grid, year=year), windowSize)
        ## filtering the image bands right away based on the single model output
        snicData = snicOutputs(naip=prepared_naip,
                               SNIC_SeedShape=SNIC_SeedShape,
                               SNIC_SuperPixelSize=SNIC_SuperPixelSize,
                               SNIC_Compactness=SNIC_Compactness,
                               SNIC_Connectivity=SNIC_Connectivity,
                               # nativeScaleOfImage=nativeScaleOfImage,
                               bandsToUse_Cluster=bandsToUse_Cluster).select(bandsToUse)
        # apply the model and clip to aoi and reclass to unsigned 8bit image
        classifiedPixelsTrim = applyRFModel(imagery=snicData, bands=bandsToUse, classifier=rfPixelTrim).uint8()
        # print(f'Exporting classified maps for ref_harmonized cell {tar_grid} using reference cell {ref_grid}')
        description = 'ref_harmonized_map_' + str(tar_grid) + "_using_" + ref_grid + '_' + str(year)
        print(' -> Saving to Google Drive: ' + description)
        # export image to asset
        task = ee.batch.Export.image.toDrive(
            image=classifiedPixelsTrim,
            description=description,
            folder=str(year),
            region=tar_gridArea.geometry(),
            scale=1,
            crs=classifiedPixelsTrim.projection(),
            maxPixels=1e13
        )
        task.start()
        while (task.status()['state'] not in ['COMPLETED', 'FAILED']):
            time.sleep(30)
        human_readable = datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d %H:%M:%S')
        print(f' -> Export finished at {human_readable}')
    except:
        # print('failed to process asset '+base_gee_asset2.format(tar_grid=tar_grid, ref_grid=ref_grid, year=year))
        print(f'failed to harmonize grid {tar_grid} to {ref_grid}.')
