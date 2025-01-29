import ee
import geemap
import geopandas as gpd
import os
from agroforestry.config import *  # moving away from defining variable from here so I can itorate over them within the script  
from agroforestry.geeHelpers import *
from agroforestry.naipProcessing import *
from agroforestry.snicProcessing import *


# imp does not run in python 12.3 
# look into https://docs.python.org/3.11/library/importlib.html#module-importlib if I want to solve this issue

# establish connection with ee account. might require some additional configuration based on local machine 
try:
        ee.Initialize()
except Exception as e:
        ee.Authenticate()
        ee.Initialize()# if initialization, comment out the line above and go through the authentication process
## don't expect this to go smoothly or quickly... 
#try this first
# ee.Authenticate() 
## pursue the gcloud installation if you have the time and will be utilizing your current machine in the future 
## if your short on time you can use the notebook authentication which will give you about a week of use on the current machine 
# ee.Authenticate(auth_mode = "notebook")



# print("training data is being develop for the " + str(year)+ " time period")
     
#### Content require from config.py 
years = [2010, 2016,2020]
# aois = ["X12-183","X12-207"]
# might iterate this whole thing but for now just use this to pull 
rootdir = 'data/raw/'
allOptions = []
for subdir, dirs, files in os.walk(rootdir):
    for file in files:
        if file.endswith('.geojson'):
                id = os.path.join(subdir, file)[9:16]
                allOptions.append(id.replace('\\',""))

# testing 
# allOptions = allOptions[3:5]

allOptions = ["X12-32"]

for gridID in allOptions:
        # define initial sub grid 
        # initGridID = "X12-183" # primary grid = X12-601 - this need to reflect where the training data is held 
        print(gridID)
        # run version
        # runVersion = "testing1"       
        # folder storage structure
        processedData = 'data/processed/'+gridID
        print(processedData)
        dataProducts = 'data/products/'+gridID
        rawData = 'data/raw/'+gridID
        if not os.path.isdir(processedData): 
                os.makedirs(processedData)      
        if not os.path.isdir(dataProducts): 
                os.makedirs(dataProducts)
        if not os.path.isdir(rawData): 
                os.makedirs(rawData)    
        # data from GEE is place in name AOI folder in the raw data. . 
        rawSampleData = rawData + "/agroforestrySampling_"+gridID+".geojson" ## will need this to pull from the 
        processSampleData = processedData + "/agroforestrySamplingData_" + str(year) + ".geojson"
        if os.path.exists(processSampleData):
                #  Prioritize the processed data 
                pointsWithClasses = gpd.read_file(processSampleData)
        else:
                pointsWithClasses = gpd.read_file(rawSampleData)# [["presence","random","sampleStrat","geometry"]]      
                # convert the reference points to gee object 
        pointsEE = geemap.gdf_to_ee(pointsWithClasses)
        # geePrint(pointsEE)

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

        # loop over the years to produce the unique datasets for each aoi 
        for year in years:
                print(year)
                if not os.path.exists(processedData + "/agroforestrySamplingData_" + str(year) +".geojson"):
                        # generate NAIP layer 
                        naipEE = prepNAIP(aoi=pointsEE, year=year, windowSize= windowSize)
                        # geePrint(naipEE.bandNames())
                        # normal the naip data -- skipping this step because it errors with the NDVI values. If I need to do 
                        # i'll have to normalize within the prepNAIP function
                        # normalizedNAIP = normalize_by_maxes(img=naipEE, bandMaxes=bandMaxes)
                        # geePrint(normalizedNAIP)
                        # # produce the SNIC object 
                        snicData = snicOutputs(naip = naipEE,
                                                SNIC_SeedShape = SNIC_SeedShape,
                                                SNIC_SuperPixelSize = SNIC_SuperPixelSize, 
                                                SNIC_Compactness = SNIC_Compactness,
                                                SNIC_Connectivity = SNIC_Connectivity,
                                                # nativeScaleOfImage = nativeScaleOfImage,
                                                bandsToUse_Cluster = bandsToUse_Cluster)
                        # geePrint(snicData.bandNames()) # this full list is what is used to create the pixel model 
                        # extract values for the training and testing datasets 
                        extractedReferenceData = snicData.sampleRegions(collection = pointsEE, 
                                                                        scale = nativeScaleOfImage,
                                                                        geometries = True)
                        # export data --- takes a long time, maybe 5 minutes
                        try:
                            geemap.ee_to_geojson(ee_object=extractedReferenceData, filename = processedData + "/agroforestrySamplingData_" + str(year) +".geojson")
                        except:
                            print("download failed")        


