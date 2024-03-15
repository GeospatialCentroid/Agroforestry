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

allOptions = ["X12-115"]

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


