pacman::p_load(VSURF, dplyr,sf)


setwd("~/GitHub/Agroforestry")

# read in all gpd objects --- state the paths within the config file 
grid <- st_read("data/processed/griddedFeatures/twelve_mi_grid_uid.gpkg")
# ne = gpd.read_file(r"data\processed\griddedFeatures\nebraska_counties.gpkg")
# points = gpd.read_file(r"data\processed\testSamplingData.geojson")
# subSamplePoints = gpd.read_file(r"data\processed\subGridSampling.geojson")

# usda tree reference layer 
# usdaRef = gpd.read_file(r"data\raw\referenceData\Antelope_ALL_metrics_LCC_edited.shp")
# define year
year <- 2016
# define initial sub grid 
initGridID <- "X12-601"





varaibleSelection <- function(year, gridID){
  
  # define file path for inport and export 
  filePath <- paste0("data/processed/", initGridID)
  
  data <- list.files(filePath, pattern = "agroforestrySamplingData.geojson", recursive = TRUE, full.names = TRUE) |>
    st_read()|> 
    st_drop_geometry()
  
  # subset predictor data and presence column
  # remove all na from dataframe
  test2 <-complete.cases(data) 
  data <- data[test2,]
  
  predictorVar <- data |> select(-presence, -sampleStrat, -random, -id)
  responseVar <-  data |> select(presence)
  # drop all column from bioValues set as well so the same data is used for maxnet modeling.
  
  # #vsurf
  ### Considered altering the number of trees, 100 is somewhat low for the
  # number of predictors used. It was a time concern more then anything.
  # change for 30 arc second run 
  vsurfThres <- VSURF_thres(x=predictorVar , y=as.factor(responseVar$presence))
  ###
  #correlation matrix
  ###
  
  # define predictor list based on Run
  inputPredictors <- vsurfThres$varselect.thres
  
  # ordered predictors from our variable selection
  orderPredictors <- predictorVar[,c(inputPredictors)]
  # Calculate correlation coefficient matrix
  correlation <-cor(orderPredictors, method="pearson")
  #change self correlation value
  
  # #define the list of top 15 predictors
  varNames <- colnames(correlation)
  # empty list containing the variables tested
  varsTested <- c()
  #loop through the top 5 predictors to remove correlated varables.
  for( i in 1:5){
    print(varNames[i])
    if(varNames[i] %in% varNames){
      # add variable to the test list
      varsTested <- c(varsTested, varNames[i])
      # Test for correlations with predictors
      vars <- correlation[(i+1):nrow(correlation),i] > 0.7 | correlation[(i+1):nrow(correlation),i] < -0.7 ## this is not getting filtered and that's ok really... 
      # Select correlated values names
      corVar <- names(which(vars == TRUE))
      #test is any correlated variables exist
      if(length(corVar) >0 ){
        # loop through the list of correlated variables
        varNames <- varNames[!varNames  %in% corVar]
        print(paste0("the variable ", corVar, " was removed"))
      }
    }else{
      print("this variable has been removed already")
    }
  }
  
  # include all variables that were tested.
  for(p in varsTested){
    if(p %in% varNames){
    }else{
      varNames <- c(varNames, p)
    }
  }# It's a little bit confusing why variable are being dropped after they area tested. Correlation
  # should be the same in both directs. This is just a test to make sure it works.
  
  
  #create a dataframe of the top predictors and
  rankPredictors <- data.frame(matrix(nrow = length(colnames(correlation)),ncol = 3))
  rankPredictors$varNames <- colnames(correlation)
  rankPredictors$importance <- vsurfThres$imp.varselect.thres
  rankPredictors$includeInFinal <- colnames(correlation) %in% varNames
  rankPredictors <- rankPredictors[,4:6]

  #export to a file location 
  write.csv(x = rankPredictors, file = paste0(filePath,"/variableSelection.csv"))
  
  return(rankPredictors)
}



varaibleSelection(year = year, gridID = initGridID)

