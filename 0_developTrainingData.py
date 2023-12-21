import ee
import geemap
import geopandas as gpd
from agroforestry.config import * 
from agroforestry.geeHelpers import *
from agroforestry.naipProcessing import *
from agroforestry.snicProcessing import *

"C:\Users\carverd\AppData\Local\r-miniconda\python.exe" 

# establish connection with ee account. might require some additional configuration based on local machine 
ee.Initialize()
# if initialization, comment out the line above and go through the authentication process
## don't expect this to go smoothly or quickly... 
#try this first
# ee.Authenticate() 
## pursue the gcloud installation if you have the time and will be utilizing your current machine in the future 
## if your short on time you can use the notebook authentication which will give you about a week of use on the current machine 
# ee.Authenticate(auth_mode = notebook)


print("training data is being develop for the " + str(year)+ " time period")
     
# convert the reference points to gee object 
pointsEE = geemap.gdf_to_ee(subSamplePoints)
# geePrint(pointsEE)

# generate NAIP layer 
naipEE = prepNAIP(aoi=pointsEE, year=year)
# geePrint(naipEE)

# normal the naip data
normalizedNAIP = normalize_by_maxes(img=naipEE, bandMaxes=bandMaxes)

# # produce the SNIC object 
snicData = snicOutputs(naip = normalizedNAIP, SNIC_NeighborhoodSize = SNIC_NeighborhoodSize,
                       SNIC_SeedShape = SNIC_SeedShape, SNIC_SuperPixelSize = SNIC_SuperPixelSize, 
                       SNIC_Compactness = SNIC_Compactness, SNIC_Connectivity = SNIC_Connectivity,
                       nativeScaleOfImage = nativeScaleOfImage, bandsToUse_Cluster = bandsToUse_Cluster)
# geePrint(snicData)

# extract values for the training and testing datasets 
extractedReferenceData = snicData.sampleRegions(collection = pointsEE, 
                                                scale = nativeScaleOfImage,
                                                geometries = True)
# geePrint(extractedReferenceData)
# export data 
refData = geemap.ee_to_geojson(ee_object=extractedReferenceData,
                               filename="data/processed/trainingdataset_withClasses.geojson")
# options to export to different file types
# refData2 = geemap.ee_to_csv(ee_object=extractedReferenceData,
#                             filename="data/processed/trainingdataset_withClasses.csv")
# print(refData)

                              


