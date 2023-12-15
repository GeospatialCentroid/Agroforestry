# config.py
import geopandas as gpd

# read in all gpd objects --- state the paths within the config file 
grid = gpd.read_file(r"data\processed\griddedFeatures\twelve_mi_grid_uid.gpkg")
ne = gpd.read_file(r"data\processed\griddedFeatures\nebraska_counties.gpkg")
points = gpd.read_file(r"data\processed\testSamplingData.geojson")
subSamplePoints = gpd.read_file(r"data\processed\subGridSampling.geojson")
# once we establish a sampling method we should need points with classes. 
pointsWithClasses = gpd.read_file(r"data\processed\agroforestrySamplingData.geojson")
# usda tree reference layer 
usdaRef = gpd.read_file(r"data\raw\referenceData\Antelope_ALL_metrics_LCC_edited.shp")
# define year
year = 2016
# define initial sub grid 
initGridID = "X12-601"



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
nativeScaleOfImage = 4 # this should be one for production, using larger number for performance in the testing steps 

# SNIC based parametes 
## Defining the Seed Grid
# The superpixel seed location spacing, in pixels. Has a big effect on the total number of clusters generated
SNIC_SuperPixelSize= 8
SNIC_SuperPixelSize_range = [3,5,8,12,16,20,30,50,80,100] # this is the parameter with the most number of options   
# Either 'square' or 'hex'. hex has a more variable position set across the landscape
SNIC_SeedShape='hex'
SNIC_SeedShape_range = ["hex","square"]

## snic algorythem changes directly
# Larger values cause clusters to be more compact (square/hexagonal). Anything over 1 seems to cause this. 
# Setting this to 0 disables spatial distance weighting.
SNIC_Compactness=0
SNIC_Compactness_range = [0,0.25,0.5,0.75,1]
# Connectivity. Either 4 or 8. Did not seem to effect to much... 
SNIC_Connectivity=4
SNIC_Connectivity_range = [4,8]

# Tile neighborhood size (to avoid tile boundary artifacts). Defaults to 2 * size.
#  SNIC_NeighborhoodSize=2 * SNIC_SuperPixelSize -- dependent on SuperPixelSize so will not redefine in testing 

# RandomForest parameters
### need to do a little reading to understand what is really worth testing here. 0
nTrees = 10
nTrees_range = [2,4,6,10,20]
setSeed = 5

# Parameters to test 
