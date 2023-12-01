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