import ee
import geemap
import geopandas as gpd
import numpy as np
from agroforestry.config import * 
from agroforestry.geeHelpers import *
from agroforestry.naipProcessing import *
from agroforestry.snicProcessing import *
from agroforestry.randomForest import *
from agroforestry.exportFunctions import *




# establish connection with ee account. might require some additional configuration based on local machine 
ee.Initialize()
# if issues see 0_develop training data for suggestions 

# import training dataset 
trainingData = gpd.read_file(filename="data/processed/trainingdataset_withClasses.geojson")
# select the training class of interest and drop unnecessary columns
trainingSubset =  trainingData[trainingData.sampleStrat == "subgrid"]
# convert to ee object
pointsEE = geemap.gdf_to_ee(gdf=trainingSubset)
# subset testing and training data 
training = pointsEE.filter(ee.Filter.gt('random', test_train_ratio))
testing = pointsEE.filter(ee.Filter.lte('random',test_train_ratio))
# traing the rf model 
rfPixelTrim = trainRFModel(bands=vsurfNoCor,  inputFeature=training, nTrees=nTrees,setSeed=setSeed )
## run validation using the testing set 
pixelValidationTrim = testRFClassifier(classifier=rfPixelTrim, testingData= testing)



# define the aoi
aoiID = initGridID # something to itorate over for now is defined based on the input training dataset 
# this becomes the AOI to used in the prepNAIP function. I'll need to edit it so that it converts the input data into a bbox 
gridSelect = grid.loc[grid.Unique_ID == aoiID]

# convert to a gee object 
aoi1 = geemap.gdf_to_ee(gridSelect)
# create a sub grid for downloading 
downloadGrids = geemap.fishnet(aoi1.geometry(), rows=6, cols=4, delta=0)


# generate the USDA reference object 
# usda1 = processUSDARef(aoiGrid = gridSelect, usdaRef=usdaRef)
## this is still a vector product


# generate NAIP layer 
naipEE = prepNAIP(aoi=aoi1, year=year,windowSize=windowSize)

# produce the SNIC object 
## filtering the image bands right away based on the single model output 
snicData = snicOutputs(naip = naipEE,
                       SNIC_SeedShape = SNIC_SeedShape, 
                       SNIC_SuperPixelSize = SNIC_SuperPixelSize, 
                       SNIC_Compactness = SNIC_Compactness, 
                       SNIC_Connectivity = SNIC_Connectivity,
                       # nativeScaleOfImage = nativeScaleOfImage, 
                       bandsToUse_Cluster = bandsToUse_Cluster).select(vsurfNoCor)
# apply the model and clip to aoi and reclass to unsigned 8bit image 
classifiedPixelsTrim = applyRFModel(imagery=snicData, bands=vsurfNoCor,classifier=rfPixelTrim).clip(aoi1).uint8()

# test the model 
modelExtractedVals = classifiedPixelsTrim.sampleRegions(
    collection=testing, scale=1, geometries=False
)

# Generate a confusion matrix on the current classification 
combinedAccuracy = modelExtractedVals.errorMatrix("presence", "remapped")

# export imagery 
exportImagery = True
if exportImagery:
    ### export to google drive
    ### slow ~ > 10m for export but it does seem to work.... 
    ### should probably try at 1m just to see what happens. 
    ### track progress at https://code.earthengine.google.com/tasks
    nGrids = downloadGrids.size()
    # this is still a GEE object so it wont work in python loops 
    for i in range(24):  #range(len(downloadGrids)) # defining the value manually 
        print(i)
        clipArea = ee.Feature(downloadGrids.toList(nGrids).get(i))
        test2 = classifiedPixelsTrim.clip(clipArea)
        task = ee.batch.Export.image.toDrive(
            image=test2,
            scale= 1,
            description='testExport_0124'+str(i),
            folder='agroforestry',
            region= clipArea.geometry()
            # maxPixels = 1e10
        )
        task.start()


## add a condtional statement here to determine if the file should be downloaded or not. 
exportDictionary = False
if exportDictionary: 
    # save model parameters to a spreadsheet 1
    # create a dictionary so we can export information 
    dic2 = ee.Dictionary({
        "gridID" : initGridID,
        "naipYear" : year,
        "totalNumberTest" :  testing.size(),
        "SNIC_SuperPixelSize" : SNIC_SuperPixelSize, 
        "SNIC_Compactness" : SNIC_Compactness,
        "SNIC_Connectivity": SNIC_Connectivity, 
        "SNIC_SeedShape": SNIC_SeedShape,
        "nTrees": nTrees,
        'allValues' : combinedAccuracy.array(),
        'overallAccuracy' : combinedAccuracy.accuracy()})
    # write out the data
    geemap.dict_to_csv(dic2, out_csv= "data/processed/appliedModels/" + initGridID+ "_" + str(year) + runVersion+  ".csv")
