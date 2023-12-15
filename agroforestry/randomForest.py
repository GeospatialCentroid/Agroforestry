def trainRFModel(inputFeature,nTrees, setSeed, bands):
    import ee

    # generate a rf model 
    trainingclassifier = ee.Classifier.smileRandomForest(numberOfTrees = nTrees, seed = setSeed).train(features= inputFeature,
                                                                                           classProperty = 'presence', 
                                                                                           inputProperties = bands)
    
    return trainingclassifier

def applyRFModel(imagery, bands, classifier):
    # subset bands from the image of interest
    imagesSelect = imagery.select(bands)
    # classify the image
    classified_image = imagesSelect.classify(classifier)
    # might be more here with accuracy accessments 

    return(classified_image)

def testRFClassifier(testingData,classifier):
    import geemap
    ## run validation using the testing set 
    validation = testingData.classify(classifier)
    accuracy1 = validation.errorMatrix("presence", "classification")
    total = accuracy1.accuracy()
    ## these return two values, need to figure out what actually being said and how best to store them
    # consumer = accuracy1.consumersAccuracy()
    # producer = accuracy1.producersAccuracy()
    # need to find a way to convert these from GEE objects to straight numbers to export in DF
    # Only a single object will print.  
    return total

#"data/processed/trainingdataset_withClasses.geojson"
def trainModels(filename,test_train_ratio,nTrees,setSeed,bandsToUse_Cluster,bandsToUse_Pixel):
    import ee
    import geemap
    import geopandas as gpd    
    # import training dataset 
    trainingData = gpd.read_file(filename=filename)
    # print(type(trainingData))
    # select the training class of interest and drop unnecessary columns
    trainingSubset =  trainingData[trainingData.sampleStrat == "subgrid"]
    # print(trainingSubset)
    # convert to ee object
    pointsEE = geemap.gdf_to_ee(gdf=trainingSubset)
    # subset testing and training data 
    training = pointsEE.filter(ee.Filter.gt('random', test_train_ratio))
    testing = pointsEE.filter(ee.Filter.lte('random',test_train_ratio))
    # traing the rf model 
    rfCluster = trainRFModel(bands=bandsToUse_Cluster, inputFeature=training, nTrees=nTrees,setSeed=setSeed)
    rfPixel = trainRFModel(bands=bandsToUse_Pixel, inputFeature=training, nTrees=nTrees,setSeed=setSeed)
    ## run validation using the testing set 
    clusterValidation = testRFClassifier(classifier=rfCluster, testingData= testing)
    pixelValidation = testRFClassifier(classifier=rfPixel, testingData= testing)
    # cant print tuple with this function'
    return(testing, rfCluster, rfPixel)