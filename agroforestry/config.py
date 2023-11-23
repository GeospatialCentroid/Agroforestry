# config.py
import geopandas as gpd

# read in all gpd objects --- state the paths within the config file 
grid = gpd.read_file(r"data\processed\griddedFeatures\twelve_mi_grid_uid.gpkg")
ne = gpd.read_file(r"data\processed\griddedFeatures\nebraska_counties.gpkg")
points = gpd.read_file(r"data\processed\testSamplingData.geojson")
# once we establish a sampling method we should need points with classes. 
pointsWithClasses = gpd.read_file(r"data\processed\agroforestrySamplingData.geojson")
# define year
year = 2016


# define constant variables. -- this will probably be moved into the config.py file
# visualization layers 
threeBandsToDraw=['R', 'G','B']
threeBandsToDraw_Mean=['R_mean', 'G_mean','B_mean']

# Test train split ratio -- value between 0-1  
# All values above this value will be part of the training data 
# all values less then or equal too will be in the testing data
# the value is a assigned randomly across a 0-1 distribution.  
# ex. 0.4 would imply, 60% of records to train, 40% to test 
test_train_ratio = 0.4

# these are hard coded parameters come back to them if you start
# altering the number of input bands to the SNIC function
# selection layers to use in the pixel based and cluster based modeling process 
bandsToUse_Pixel = ['R', 'G','B', "N", "nd",'R_mean', 'G_mean','B_mean', "N_mean", "nd_mean" ] 
bandsToUse_Cluster = ['R_mean', 'G_mean','B_mean', "N_mean", "nd_mean"]
# define the max value of the individuals to normalize elemenst 
bandMaxes=[255, 255, 255,255,1] #  represents 'R', 'G','B', "N", "nd"

# set the scale of the input image
nativeScaleOfImage = 4

# SNIC based parametes 
# The superpixel seed location spacing, in pixels. Has a big effect on the total number of clusters generated
SNIC_SuperPixelSize= 8

# Larger values cause clusters to be more compact (square/hexagonal). Anything over 1 seems to cause this. 
# Setting this to 0 disables spatial distance weighting.
SNIC_Compactness=0
# Connectivity. Either 4 or 8. Did not seem to effect to much... 
SNIC_Connectivity=4
# Either 'square' or 'hex'. hex has a more variable position set across the landscape
SNIC_SeedShape='hex'
# Tile neighborhood size (to avoid tile boundary artifacts). Defaults to 2 * size.
SNIC_NeighborhoodSize=2 * SNIC_SuperPixelSize

# RandomForest parameters
nTrees = 10
setSeed = 5
