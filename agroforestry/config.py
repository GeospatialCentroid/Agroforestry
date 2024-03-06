# config.py
import geopandas as gpd
import pandas as pd
import numpy as np
import os

# read in all gpd objects --- state the paths within the config file 
grid = gpd.read_file("data/processed/griddedFeatures/twelve_mi_grid_uid.gpkg")
# ne = gpd.read_file(r"data\processed\griddedFeatures\nebraska_counties.gpkg")
# points = gpd.read_file(r"data\processed\testSamplingData.geojson")
# subSamplePoints = gpd.read_file(r"data\processed\subGridSampling.geojson")

# usda tree reference layer 
# usdaRef = gpd.read_file(r"data\raw\referenceData\Antelope_ALL_metrics_LCC_edited.shp")
# define year
year = 2020
# define initial sub grid 
initGridID = "X12-440" # primary grid = X12-601 - this need to reflect where the training data is held 

# run version
runVersion = "testing1"

# folder storage structure
processedData = 'data/processed/'+initGridID
dataProducts = 'data/products/'+initGridID
rawData = 'data/raw/'+initGridID
if not os.path.isdir(processedData): 
    os.makedirs(processedData)
if not os.path.isdir(dataProducts): 
    os.makedirs(dataProducts)
if not os.path.isdir(rawData): 
    os.makedirs(rawData)

# data from GEE is place in name AOI folder in the raw data. . 
rawSampleData = rawData + "/agroforestrySampling_"+initGridID+".geojson" ## will need this to pull from the 
processSampleData = processedData + "/agroforestrySamplingData_" + str(year) + ".geojson"
if os.path.exists(processSampleData):
  #  Prioritize the processed data 
  pointsWithClasses = gpd.read_file(processSampleData)
else:
  pointsWithClasses = gpd.read_file(rawSampleData)# [["presence","random","sampleStrat","geometry"]]


# define constant variables. -- this will probably be moved into the config.py file
# visualization layers 
threeBandsToDraw=['R', 'G','B']
threeBandsToDraw_Mean=['R_mean', 'G_mean','B_mean']

# Test train split ratio -- value between 0-1  
test_train_ratio = 0.8

## read in the variables selected
variableSelection = processedData + "/variableSelection"+str(year)+".csv" 

if os.path.exists(variableSelection):
  selectedVariables = pd.read_csv(variableSelection)
  # vsurf select variables top 10 
  ## I want to read in this data as a file based on export from R 
  ## need a condition statement to make sure the file exists. 
  vsurfWithCor = selectedVariables.iloc[:10]["varNames"].tolist() 
  # vsurf select variables with removed correlations
  vsurfNoCor = selectedVariables.query('includeInFinal == True').iloc[:10]["varNames"].tolist()       

    # define neighborGrids 
  ## I want to read in this data as a file based on export from R 
  ## need a condition statement to make sure the file exists. 
  neighborGrid = pd.read_csv(processedData + "/neighborGrids.csv")
  grid8 = neighborGrid[neighborGrid['poisition'].isin([1])]
  grid16 = neighborGrid[neighborGrid['poisition'].isin([1,2])]
  grid24 = neighborGrid[neighborGrid['poisition'].isin([1,2,3])]
  grid36 = neighborGrid[neighborGrid['poisition'].isin([1,2,3,4])]


# these are hard coded parameters come back to them if you start
# altering the number of input bands to the SNIC function
# selection layers to use in the pixel based and cluster based modeling process 
bandsToUse_Pixel = ['R_mean', 'G_mean', 'B_mean', 'N_mean', 'nd_mean', 'savg_g_mean', 'contrast_g_mean', 'entropy_g_mean',
                     'savg_n_mean', 'contrast_n_mean', 'entropy_n_mean', 'R', 'G', 'B', 'N', 'savg_g', 'contrast_g', 'entropy_g',
                       'savg_n', 'contrast_n', 'entropy_n', 'nd', 'nd_sd_neighborhood', 'nd_mean_neighborhood']
## only bands that are based on mean area measures
bandsToUse_Cluster = ['R_mean', 'G_mean','B_mean', "N_mean", "nd_mean",'savg_g_mean', 'contrast_g_mean', 'entropy_g_mean', 'savg_n_mean',
                       'contrast_n_mean', 'entropy_n_mean']



# define the max value of the individuals to normalize elemenst 
bandMaxes=[255, 255, 255,255,1] #  represents 'R', 'G','B', "N", "nd"

# set the scale of the input image
nativeScaleOfImage = 1 # this should be one for production, using larger number for performance in the testing steps 

## these could all be set based on a maximum value returned 

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

# Tile neighborhood size (to avoid tile boundary artifacts). Defaults to 2 * size.
#  SNIC_NeighborhoodSize=2 * SNIC_SuperPixelSize -- dependent on SuperPixelSize so will not redefine in testing 

# RandomForest parameters
### need to do a little reading to understand what is really worth testing here. 0
nTrees = 10
nTrees_range = np.arange(2, 20, 2)
setSeed = 5

# window size for average NDVI and glcm 
windowSize = 8



# Parameters to test 
