import ee
import geemap
import geopandas as gpd
import pandas as pd
from datetime import date
from agroforestry.config import * 
from agroforestry.geeHelpers import *
from agroforestry.naipProcessing import *
from agroforestry.snicProcessing import *
from agroforestry.randomForest import *
# read in the parameter testing script 

###
# section 1 : establish rf models based on sampling area
# 
###

# establish connection with ee account. might require some additional configuration based on local machine 
ee.Initialize()
# if issues see 0_develop training data for suggestions 

## define the input dataset. This determines you gereral training location and will be changed for modeling different areas over time 
vals = trainModels(filename="data/processed/trainingdataset_withClasses.geojson",
                   nTrees=nTrees,
                   setSeed=setSeed,
                   test_train_ratio=test_train_ratio,
                   bandsToUse_Cluster=bandsToUse_Cluster,
                   bandsToUse_Pixel=bandsToUse_Pixel,
                   bandsToUse_pixelTrim= vsurfNoCor)
testing = vals[0]
rfCluster = vals[1]
rfPixel = vals[2]
rfPixelTrim = vals[3]

###
# section 2 : establish region which models are being applied. This can be change in the standard workflow but will remain consistent in the parameter testing section
# initGridID is define in the config file so now. 
###


# define the aoi
aoiID = initGridID # something to itorate over for now is defined based on the input training dataset 
# this becomes the AOI to used in the prepNAIP function. I'll need to edit it so that it converts the input data into a bbox 
gridSelect = grid.loc[grid.Unique_ID == aoiID]

# convert to a gee object 
aoi1 = geemap.gdf_to_ee(gridSelect)

# generate NAIP layer 
naipEE = prepNAIP(aoi=aoi1, year=year,windowSize=windowSize)

# normal the naip data
# normalizedNAIP = normalize_by_maxes(img=naipEE, bandMaxes=bandMaxes)

###
# section 3: generate the trimed pixel model  
def testModel(naip,SNIC_SeedShape,SNIC_SuperPixelSize,SNIC_Compactness,SNIC_Connectivity,bandsToUse_Cluster,
              rfPixelTrim, bandsToUse_PixelTrim,testParaName):
    # testParaName : was used in file naming... 
    
    # produce the SNIC object 
    snicData = snicOutputs(naip = naip,
                        SNIC_SeedShape = SNIC_SeedShape, 
                        SNIC_SuperPixelSize = SNIC_SuperPixelSize, 
                        SNIC_Compactness = SNIC_Compactness, 
                        SNIC_Connectivity = SNIC_Connectivity,
                        bandsToUse_Cluster = bandsToUse_Cluster)
    # geePrint(snicData.bandNames())
    
    # apply the rf model to the pixels 
    classifiedPixels = applyRFModel(imagery=snicData,
                                     bands=bandsToUse_PixelTrim,
                                     classifier=rfPixelTrim)

    # extact values to the testing  dataset
    modelExtractedVals = classifiedPixels.sampleRegions(
        collection=testing, scale=1, geometries=False
    )

    # Generate a confusion matrix on the current classification 
    combinedAccuracy = modelExtractedVals.errorMatrix("presence", "classified")
    # geePrint(testing.size())
    # create a dictionary so we can export information 
    # dic2 = ee.Dictionary({
    #     "gridID" : initGridID,
    #     "naipYear" : year,
    #     "totalNumberTest" :  testing.size(),
    #     "SNIC_SuperPixelSize" : SNIC_SuperPixelSize, 
    #     "SNIC_Compactness" : SNIC_Compactness,
    #     "SNIC_Connectivity": SNIC_Connectivity, 
    #     "SNIC_SeedShape": SNIC_SeedShape,
    #     "nTrees": nTrees,
    #     'allValues' : combinedAccuracy.array(),
    #     'overallAccuracy' : combinedAccuracy.accuracy()})
    
    # try saves as features colleciton 
    # Make a collection of points.
    list_of_features = [ee.Feature(ee.Geometry.Point(-62.54, -27.32), {"gridID" : initGridID,
        "naipYear" : year,
        "totalNumberTest" :  testing.size(),
        "SNIC_SuperPixelSize" : SNIC_SuperPixelSize, 
        "SNIC_Compactness" : SNIC_Compactness,
        "SNIC_Connectivity": SNIC_Connectivity, 
        "SNIC_SeedShape": SNIC_SeedShape,
        "nTrees": nTrees,
        'allValues' : combinedAccuracy.array(),
        'overallAccuracy' : combinedAccuracy.accuracy()})]
  
    list_of_features_fc = ee.FeatureCollection(list_of_features)
    name = testParaName + "_" + str(i) +"_"+ "20240116"
    task = ee.batch.Export.table.toDrive(
      collection=list_of_features_fc,
      description= name,
      folder='Earth Engine',
      fileFormat='CSV')
    task.start()

    # geemap.dict_to_csv(dic2, out_csv= "data/processed/parameterTesting/" + testParaName+ "_" + str(i) +"20240110.csv")
    # export table to drive -- base EE function. should pass to the task tracking elements. might be a better option. 
    # needs to go from dictionary to collection 
    # Export.table.toDrive(collection, description, folder, fileNamePrefix, fileFormat, selectors, maxVertices)





# apply over a SNIC_SeedShape_range
# this only has two options 
for i in SNIC_SeedShape_range:
    print(i)
    testModel(naip = naipEE,
              SNIC_SeedShape = i,
              SNIC_SuperPixelSize = SNIC_SuperPixelSize,
              SNIC_Compactness = SNIC_Compactness,
              SNIC_Connectivity = SNIC_Connectivity,
              bandsToUse_Cluster = bandsToUse_Cluster,
              rfPixelTrim = rfPixelTrim,
              bandsToUse_PixelTrim = vsurfNoCor,
              testParaName= "SNIC_SeedShape_range" )
    

# apply over a SNIC_Connectivity_range
# this only has two options 
for i in SNIC_Connectivity_range:
    print(i)
    testModel(naip = naipEE,
              SNIC_SeedShape = SNIC_SeedShape,
              SNIC_SuperPixelSize = SNIC_SuperPixelSize,
              SNIC_Compactness = SNIC_Compactness,
              SNIC_Connectivity = i,
              bandsToUse_Cluster = bandsToUse_Cluster,
              rfPixelTrim = rfPixelTrim,
              bandsToUse_PixelTrim = vsurfNoCor,
              testParaName= "SNIC_Connectivity_range" )

# apply over a SNIC_Compactness_range
for i in SNIC_Compactness_range:
    print(i)
    testModel(naip = naipEE,
              SNIC_SeedShape = SNIC_SeedShape,
              SNIC_SuperPixelSize = SNIC_SuperPixelSize,
              SNIC_Compactness = i,
              SNIC_Connectivity = SNIC_Connectivity,
              bandsToUse_Cluster = bandsToUse_Cluster,
              rfPixelTrim = rfPixelTrim,
              bandsToUse_PixelTrim = vsurfNoCor,
              testParaName= "SNIC_Compactness_range")

# apply over a SNIC_SuperPixelSize_range
for i in SNIC_SuperPixelSize_range:
    print(i)
    testModel(naip = naipEE,
              SNIC_SeedShape = SNIC_SeedShape,
              SNIC_SuperPixelSize = i,
              SNIC_Compactness = SNIC_Compactness,
              SNIC_Connectivity = SNIC_Connectivity,
              bandsToUse_Cluster = bandsToUse_Cluster,
              rfPixelTrim = rfPixelTrim,
              bandsToUse_PixelTrim = vsurfNoCor,
              testParaName= "SNIC_SuperPixelSize_range")
    
    
    
    
    
    
    
    
    ### 20240116 
    ### old version of the classification function 
    # def testModel(naip,SNIC_SeedShape,SNIC_SuperPixelSize,SNIC_Compactness,SNIC_Connectivity,bandsToUse_Cluster,
    #           rfCluster, rfPixel, bandsToUse_Pixel,testParaName):
    #           # bandsToUse_pixelTrim, rfPixelTrim # not added just yet... 

    # # def geePrint(feature):
    # #     return print(feature.getInfo())


    # # produce the SNIC object 
    # snicData = snicOutputs(naip = naip,
    #                     SNIC_SeedShape = SNIC_SeedShape, 
    #                     SNIC_SuperPixelSize = SNIC_SuperPixelSize, 
    #                     SNIC_Compactness = SNIC_Compactness, 
    #                     SNIC_Connectivity = SNIC_Connectivity,
    #                     bandsToUse_Cluster = bandsToUse_Cluster)
    # # geePrint(snicData.bandNames())

    # # apply the rf model to the cluster imagery 
    # classifiedClusters = applyRFModel(imagery=snicData,
    #                                    bands=bandsToUse_Cluster,
    #                                      classifier=rfCluster)
    # # geePrint(classifiedClusters)

    # # apply the rf model to the pixels 
    # classifiedPixels = applyRFModel(imagery=snicData,
    #                                  bands=bandsToUse_Pixel,
    #                                  classifier=rfPixel)

    # # generate the ensamble model 
    # combinedModels = classifiedPixels.add(classifiedClusters)
    # # reclass the image so it is a 0,1 value set 
    # from_list = [0, 1, 2]
    # # A corresponding list of replacement values (10 becomes 1, 20 becomes 2, etc).
    # to_list = [0, 0, 1]
    # combinedModelsReclass =  combinedModels.remap(from_list, 
    #                                               to_list,
    #                                                 bandName='classification')
    # # geePrint(combinedModelsReclass)

    # # extact values to the testing  dataset
    # combinedModelsExtractedVals = combinedModelsReclass.sampleRegions(
    #     collection=testing, scale=1, geometries=False
    # )

    # # Generate a confusion matrix on the current classification 
    # combinedAccuracy = combinedModelsExtractedVals.errorMatrix("presence", "remapped")
    # geePrint(testing.size())
    # # create a dictionary so we can export information 
    # dic2 = ee.Dictionary({
    #     "gridID" : initGridID,
    #     "naipYear" : year,
    #     "totalNumberTest" :  testing.size(),
    #     "SNIC_SuperPixelSize" : SNIC_SuperPixelSize, 
    #     "SNIC_Compactness" : SNIC_Compactness,
    #     "SNIC_Connectivity": SNIC_Connectivity, 
    #     "SNIC_SeedShape": SNIC_SeedShape,
    #     "nTrees": nTrees,
    #     'allValues' : combinedAccuracy.array(),
    #     'overallAccuracy' : combinedAccuracy.accuracy()})
    
    # geemap.dict_to_csv(dic2, out_csv= "data/processed/parameterTesting/" + testParaName+ "_" + str(i) +"20240110.csv")
    # # export table to drive -- base EE function. should pass to the task tracking elements. might be a better option. 
    # # needs to go from dictionary to collection 
    # # Export.table.toDrive(collection, description, folder, fileNamePrefix, fileFormat, selectors, maxVertices)
