# 202411-7 update 
# take aways from inperson meeting with Gabriel. 
# need spatially explicted representation of change 
# for 2010-2016 and 2016-2020 
## gain, loss, and stability 
## with those areas calculated determine the percent area in riparian, crop lands,
## everything else assume grass lands 

## CSB layers from https://www.nass.usda.gov/Research_and_Science/Crop-Sequence-Boundaries/index.php
## 2010 crop reference 
download.file(url = "https://www.nass.usda.gov/Research_and_Science/Crop-Sequence-Boundaries/datasets/NationalCSB_2008-2015_rev23.zip",
              destfile = "data/csb")
## 2016 crop reference 
download.file(url = "https://www.nass.usda.gov/Research_and_Science/Crop-Sequence-Boundaries/datasets/NationalCSB_2012-2019_rev23.zip",
              destfile = "data/csb")
## 2020 crop reference 
download.file(url = "https://www.nass.usda.gov/Research_and_Science/Crop-Sequence-Boundaries/datasets/NationalCSB_2016-2023_rev23.zip",
              destfile = "data/csb")



# libraries 
pacman::p_load(dplyr,sf, terra, tictoc, purrr)

# source functions 
source("agroforestry/carbonAccountingHelpers.R")

# grid features 
## add the validation score reference 
grids2010 <- sf::st_read("data/products/modelGrids_2010.gpkg") |>  assignScore() |> dplyr::mutate(year= "2010")
grids2016 <- sf::st_read("data/products/modelGrids_2016.gpkg") |>  assignScore() |> dplyr::mutate(year= "2016")
grids2020 <- sf::st_read("data/products/modelGrids_2020.gpkg") |>  assignScore() |> dplyr::mutate(year= "2020")
grids <- grids2010 |> 
  bind_rows(grids2016) |>
  bind_rows(grids2020)
### once we establish the error proporgation method we will need to read in and assign 
### values based on the model validation google sheet probably easier to do that as 
### a stand alone process outside of this workflow as the error measures are stable. 


# change over time data 
cot <- list.files(path = "data/products/changeOverTime",
                  full.names = TRUE,
                  pattern = ".tif")

# crop data 
## likley be a named list of the three different vector files 
crops <- list(c2020 = c(),
              c2016 = c(),
              c2010 = c())

# define grid names 
## this will be what is itorated over
gridNames <- paste0("X12-",1:773)


testGrid <- gridNames[300]


# testing 
grid <- testGrid
cotFiles <- cot
grids <- grids
crops <- crops

calculateCarbonAreas <- function(grid, cotFiles, grids, crops){
  # read in change over time raster layer 
  raster <- cotFiles[grepl(pattern = paste0(grid,"_changeOverTime"), x = cotFiles)] |>
    terra::rast()
  # riparian 
  r1 <- raster$RiparianMask
  # trees 
  t1 <- raster$ChangeOverTime
  rm(raster)
  
  # generate the 5 raster files need
  rasters <- reclassCOT(t1)
  
  # 2010-2016 measures 
  ## change the change measure in this format for comparison agianst 
  change <- rasters$r16 - rasters$r10
  stable <- rasters$r1016
  
  # apply riparain mask 
  changeRiparain <- change * r1
  stableRiparian <- stable * r1 
  
  # apply method for crop layer... this will be a bit different 
  
  
  # convert to final values in hectare
  ## function type, stable, change 
  ### calculate total area in hectare for stable, gain, lose 
  ### return a dataframe 
  calArea <- function(type, stable, change){
    df <- data.frame(matrix(nrow = 1, ncol = 5))
    names(df) <- c("id","type", "stable", "gains", "loss")
    # assign type 
    df$type <- type
    # assign measured values 
    ## stable 
    s1 <- freq(stable)
    df$stable <- s1$count[s1$value == 1]/10000
    ## change 
    c1 <- freq(change)
    df$gains <- c1$count[c1$value == 1]/10000
    df$loss <- c1$count[c1$value == -1]/10000  
    
    
    }
  
  
  
}










# original Attempt  -------------------------------------------------------




### Agroforestry Biomass Carbon
### 
### Objectives: Estimate biomass carbon stock changes in trees outside of forest across Nebraska croplands and grasslands

### Scrip goal: integrate TOF determined area and emission factors (source: "af_lmm_updated.R")
### Method: IPCC-Tier 2, gain-loss framework. Simplified equation = (gain - losses) * area
### Gains - annual C accumulation from immature (< 20 years) and mature (>= 20 years) trees.
 # assuming that all trees in 2010 are mature 
 # there for start with changes between 2010 and 2016
    # if area is present in both years stays as areas 
    # if area is present in 2010 but not 2016 == loss
    # if area is present in 2016 but not 2010 == gain 
### Losses - C losses from disturbance and tree harvest - no specific information - proxy: area reduction

### Notes on factors: - Values are in tons of C ha-1 and ton C ha-1 yr-1

### - factors vary by age, species, and climate (moisture) :: for pilot study, consider using a simplified model with only age as predictor



### 
### Input files (name files): areas and emission factors (and associated uncertainty)
### Packages needed: 

### Steps:
###
### 1) load areas for the 3 different periods (classes 1 to 7, which disaggregate total areas by 
### timeseries presence/absence - proxy for determining age ### of stands and replacement) -
### note: a conservative assumption would be that all stands present at the beggining of the study (2010) are at mature age
      # we need to perform this analysis based on the model grid. That is the primary iterative feature 
### 2) estimate overall area uncertainty based on sampling error and confusion matrix  
      # this will come form the spreadsheet online, for now we can provide some dummy numbers and assign those to the spatial model grid feature
### 3) multiply gain and losses by the respective areas (increase or decrease) across the timeseries
      # missing something here with the specifics? check with Gabriel 
### 4) combine areas and gain and loss factors through a Monte Carlo simulation - test stability of the simulation for confidence interval to define nreps
      # seem like were simulation change in the gain and loss numbers. Not clear if we need to recalculate the change over time spatial relationships or not
### 5) generate C reports, potentially by different environments/agroforestry systems: e.g., riparian buffer, grasslands (e.g., silvopasture), and 
### croplands (e.g., alley cropping, windbreaks/hedgerows) and biomass C changes map
### 
###
###

#load libraries 
pacman::p_load(dplyr,sf, terra, tictoc, purrr)


# sources some existing functions 
source("scripts/reclassByYear.R")

# temp function for assigning a current score 
assignScore <- function(data){
  # get the unique model grids 
  uniqueModels <- unique(data$modelGrid)
  # generate a template score value 
  scores <- runif(length(uniqueModels), min=0.1, max=0.6)
  # assign a score value 
  data$validationScore <- NA 
  for(i in seq_along(uniqueModels)){
    id <- uniqueModels[i]
    val <- scores[i]
    index <- data$modelGrid == id 
    data$validationScore[index] <- val
  }
  return(data)
}

# required input data  ----------------------------------------------------
## add the validation score reference 
grids2010 <- sf::st_read("data/products/modelGrids_2010.gpkg") |>  assignScore() |> dplyr::mutate(year= "2010")
grids2016 <- sf::st_read("data/products/modelGrids_2016.gpkg") |>  assignScore() |> dplyr::mutate(year= "2016")
grids2020 <- sf::st_read("data/products/modelGrids_2020.gpkg") |>  assignScore() |> dplyr::mutate(year= "2020")
grids <- grids2010 |> 
  bind_rows(grids2016) |>
  bind_rows(grids2020)
  

# change over time data 
cot <- list.files(path = "data/products/changeOverTime",
                  full.names = TRUE,
                  pattern = ".tif")

gridIndex <- grids2010$Unique_ID[10]
cotFiles <- cot

## probably wrap the whole workflow into a function,but I don't think were there yet.... 
# processingEffort <- function(grids, gridIndex, cotFiles){
  
  # seperate out grid 
  selectGrids <- grids[grids$Unique_ID == gridIndex,]
  
  # grap error measures per each year 
  e10 <- selectGrids$validationScore[selectGrids$year == "2010"]
  e16 <- selectGrids$validationScore[selectGrids$year == "2016"]    
  e20 <- selectGrids$validationScore[selectGrids$year == "2020"]
  
  # select specific model areas 
  raster <- cotFiles[grepl(pattern = paste0(gridIndex,"_changeOverTime"), x = cotFiles)] |>
    terra::rast()
  # pull out the years 
  ## ~10 sec
  tic()
  r2010 <- raster |> getYearMap(year = "2010") 
  tic()
  r2016 <- raster |> getYearMap(year = "2016") 
  toc()
  r2020 <- raster |> getYearMap(year = "2020")
  ###!!!! 
  # need to include the reclass for 2010-2016 and 2016-2020
  
  
  # gain and loss 2016 
  ## ~10 secs
  tic()
  values2016 <- r2016 - r2010 
  toc()
  ## 0 : both predicted forest 
  ## 1 : forest in 2016 but not in 2010 
  ## -1 : forest in 2010 but not in 2016
  
  ###!!! 
  # pull the area that has stayed the same from the reclass above 
  
  
  ###
  # goal 
  # 6 measures of areas 
  # gains, loss, and stays the same for 2010-2016, 2016-2020
  # Use the spatial data for riparian, and crops, and assume grasslands for other 
  # 18 total measures 
  # 
  ###
  
  
  
  
  # using pixel counts 
  ## returns a data frame with false match in row 1 and true in row 2 
  ## ~13 seconds 
  tic()
  same2016 <- freq(values2016 == 0)$count[2]
  toc()
  gain2016 <- freq(values2016 == 1)$count[2]
  loss2016 <- freq(values2016 == -1)$count[2]
  # or reclassify 
  ## define changes 
  rSame <- rbind(c(-1,NA), c(1,NA), c(0,1))
  rGain <- rbind(c(-1,NA), c(0,NA)) # don't need the thrid because values are 1
  rLoss <- rbind(c(1,NA), c(0,NA), c(-1,1))
  ## run the reclass 
  ## ~ 8 secs total 24
  tic()
  same2016 <- classify(x = values2016,rSame)
  toc()
  gain2016 <- classify(x = values2016,rGain)
  loss2016 <- classify(x = values2016,rLoss)
  ## if the spatial component is still needed 
  
  ## without the spatial element 
  totalPixels <- nrow(r2010) * ncol(r2010)
  val2010 <- sum(values(r2010),na.rm = TRUE)
  vect2010 <- c(rep(x = 1, val2010), rep(x = 0, totalPixels-val2010))
  
  
  
  
  ### this preps things for the calculation measures, but I'm not 100% what those would be. 
  testAndFlip <- function(orignalVect, flip_probability){
    # values from the original data will be replaced if the flip probability is meet. 
    
    # recording where the condition is applied 
    state_change_indices <- c()
    # orginal sum 
    originalSum <- sum(originalVect)
    
    
    flip <- function(index, state_change_indices ){
      if (runif(1) <= flip_probability) {
        state_change_indices <- c(state_change_indices, index)
      }
      return(state_change_indices)
    }
    
    vals <- purrr::map(.x = 1:length(originalVect[1:1000]), 
                       .f = flip,
                       state_change_indices = state_change_indices) |> unlist()
    
    
    ## monte carlo
    # for (i in 1:length(originalVect)) {
    #   print(i)
    #   # generate a random number and test it it's lower the the flip probability 
    #   if (runif(1) <= flip_probability) {
    #     state_change_indices <- c(state_change_indices, i)
    #   }
    # }
    
    # # parse out changed values 
    same <- sum(originalVect[-vals])
    changes <- sum(abs(originalVect[vals] - 1))
    # add together for final result 
    result <- sum(same,changes)
    
    # there's more that can be returned but I'm just going to keep to the sum for the moment. 
    return(result) 
  }
  

  
  
  # run x number of times. Total area is returned 
  totalArea <- c()
  for(run in 1:10){
    tic()
    change <- testAndFlip(orignalVect = vect2010, flip_probability = 0.25)
    toc()
    totalArea <- c(totalArea,change)
  }
  
  # from here we can generate any summary statistics on the specific model year 
  
  # this would need to be done for each model year and doesn't tell us about the comparitive results 
  
  # 
  
  
  
  
# }







