# 202411-7 update 
# take aways from inperson meeting with Gabriel. 
# need spatially explicted representation of change 
# for 2010-2016 and 2016-2020 
## gain, loss, and stability 
## with those areas calculated determine the percent area in riparian, crop lands,
## everything else assume grass lands 



# libraries 
pacman::p_load(dplyr,sf, terra, tictoc, purrr, furrr, readr)

# source functions 
source("agroforestry/carbonAccountingHelpers.R")

# grid features 
## add the validation score reference 
grids2010 <- sf::st_read("data/products/modelGrids_2010.gpkg") |>  assignScore() |> dplyr::mutate(year= "2010")
grids2016 <- sf::st_read("data/products/modelGrids_2016.gpkg") |>  assignScore() |> dplyr::mutate(year= "2016")
grids2020 <- sf::st_read("data/products/modelGrids_2020.gpkg") |>  assignScore() |> dplyr::mutate(year= "2020")
grids <- grids2010 |> 
  bind_rows(grids2016) |>
  bind_rows(grids2020) |> 
  terra::vect()
### once we establish the error proporgation method we will need to read in and assign 
### values based on the model validation google sheet probably easier to do that as 
### a stand alone process outside of this workflow as the error measures are stable. 


# change over time data 
cot <- list.files(path = "data/products/changeOverTime",
                  full.names = TRUE,
                  pattern = ".tif")

# crop data 
## likley be a named list of the three different vector files 
crops <- list.files("data/processed/csb", 
                    pattern = ".gpkg",
                    full.names = TRUE)

# define grid names 
## this will be what is itorated over
gridNames <- paste0("X12-",1:773)


testGrid <- gridNames[378]


# testing 
grid <- testGrid
cotFiles <- cot
grids <- grids
crops <- crops


#view single scene 
## right around Scribner
## make the map of this 
## Potentally show the data aggregated mlra 
# s1 <- cot[grepl(pattern = "X12-426", x = cot)] |> rast()
# 2010-16 change measure for AGU  ---------------------------------------


change1016 <- function(grid, cotFiles, grids, crops, future = FALSE){
  # grid :: character grid id 
  # cotFiles : path to change over time data 
  # grids :: spatial layer of grids 
  # crops :: path to crop layers 
  print(paste0("Starting process for ", grid))
  # export path 
  path <- paste0("data/products/areaMeasures/grid_",grid,"_1016.csv")
  # condiditon to run or not
  if(file.exists(path)){
    print(paste0("data exist for ", grid))
    df2 <- read_csv(path)
    return(df2)
  }else{
  if(future == TRUE){
    grids <- terra::unwrap(grids)
  }
    
  # select grid spatial layer 
  ## three layers one for each year 
  g1 <- grids |> 
    terra::subset(grids$Unique_ID == grid)
  g1<-g1[1,]

  print("reading in layers")
  # read in change over time raster layer 
  raster <- cotFiles[grepl(pattern = paste0(grid,"_changeOverTime"), x = cotFiles)] |>
    terra::rast()
  # riparian 
  r1 <- raster$RiparianMask
  # trees 
  t1 <- raster$ChangeOverTime
  rm(raster)
  
    
  print("reclass")
  # generate the 5 raster files need
  ## takes about a minute... read to alter once we determine the 2016-2020 method as I don't think we will need all 5 reclasses 
  rasters <- reclass1016(t1)
  
  # gather the total classified area for each year --------------------------
  # gather the total classified area for each year --------------------------
  dftotal <- data.frame(matrix(nrow = 2, ncol = 7))
  names(dftotal) <- c("id","type", "year", "growth", "stable", "gains", "loss")
  dftotal$id <- grid
  dftotal$year <- c("2010","2016")
  dftotal$type <- "totalArea"
  dftotal$stable[1] <- freq(rasters$r10)$count[2]/10000
  dftotal$stable[2] <- freq(rasters$r16)$count[2]/10000
  
  
  # construct df to store values 
  ## this is what is returned 
  df1016 <- data.frame(matrix(nrow = 4, ncol = 7))
  names(df1016) <- c("id","type", "year", "growth", "stable", "gains", "loss")
  df1016$id <- grid
  df1016$year <- "2016"
  df1016$growth <- "mature"
  df1016$type <- c("all","riparian","crops","grass")
  
  
  
  # 2010-2016 measures 
  ## change the change measure in this format for comparison agianst 
  change <- rasters$r16 - rasters$r10
  stable <- rasters$r1016
  
  ### for change to 2016-2020 we need to know the combination of what's above. 
  ### see next section for values 
  
  
  # 2010-2016 workflow  -----------------------------------------------------
  print("all area counts")
  # assign values to storage dataframe 
  df1016 <-calArea(df = df1016, type = "all", stable = stable, change = change)
  
  
  # Process riparian  -------------------------------------------------------
  print("process riparian")
  # apply riparain mask 
  changeRiparain <- change * r1
  stableRiparian <- stable * r1 
  # assign values to storage dataframe 
  df1016 <-calArea(df = df1016,
                   type = "riparian",
                   stableRast = stableRiparian,
                   changeRast = changeRiparain)
  
  
  # crops -------------------------------------------------------------------
  print("process crops")
  cropLayers <- processCropLayer(grid = g1, 
                                 crops = crops, 
                                 stable = stable, 
                                 change = change,
                                 year = "2016",
                                 riparian = r1)
  # calculate areas 
  df1016 <-calArea(df = df1016, type = "crops", stableRast = cropLayers$stable, changeRast = cropLayers$change)
  
  # manually calculate the grass land option 
  print("process grass")
  df1016 <- calGrass(df1016)
  
  # bind with the totals data 
  df2 <- dplyr::bind_rows(dftotal, df1016)
  # export 
  write_csv(x = df2 , file = path)
  return(df2)
  }

}


# run the 10-2016 measures  ---------------------------------------------
runGrids <- gridNames # [416:length(gridNames)]
###
# seems to be an issues with 
# X12-1"   "X12-2"   "X12-3"   "X12-4"   "X12-5"   "X12-6"   "X12-7"   "X12-8"   "X12-9"   "X12-336" "X12-413" "X12-414"
# "X12-415" "X12-592"
knowErrors <- c("X12-1","X12-2","X12-3","X12-4","X12-5","X12-6","X12-7","X12-8","X12-9","X12-63",
                "X12-336", "X12-413", "X12-414","X12-415", "X12-592","X12-615")
subGrids <- runGrids[!c(runGrids %in% knowErrors)]
# 600 on 
subGrid600 <- subGrids[585:length(subGrids)]

plan(multisession, workers = 8)
# need to wrap the terra object 
gridsWrap <- terra::wrap(grids)
tic()
results2 <- furrr::future_map(subGrid600,
                              .f = change1016,
                              cotFiles = cot,
                              grids = gridsWrap,
                              crops = crops,
                              future = FALSE)

#sequential for troubleshooting 
errors <- c()
for(i in seq_along(subGrid600)){
  d1 <- FALSE 
  d1 <- try(change1016(
    grid = subGrid600[i],
    cotFiles = cotFiles,
    grids = grids,
    crops = crops,
    future = FALSE
  ))
  if(class(d1)[1] == "try-error"){
    errors <- append(errors, values = runGrids[i])
  }
}
purrr::map(runGrids,
           .f = change1016,
           cotFiles = cot,
           grids = grids,
           crops = crops,
           future = FALSE )

toc()
# 7 grids multisession 329.803 sec elapsed



# Assing the carbon measures  ---------------------------------------------
# 
# Here are the carbon multiplication factors:
# Annual growth (C gain) of existing (mature) stands: 1.8463 tC/ha
# Annual growth of new (young) stands: 3.4963 tC/ha
# C loss of mature stands*: 81.8757 tC/ha
# C loss of young stands* (absent in 2020, but present in 2016 and not present in 2010): 13.9852 tC/ha
# The losses need to be annualized, so basically divided by 6 in 2010-2016 period or by 4 in the 2016-2020 period. 
# This would the loss of young stands in 2020 to the same annual accumulation rate of 3.49 tC/ha.


## applying the measures 
# 1. all stands that were present in 2010 and 2016 get a growth rate of 1.8462 
# 2. stands not present in 2010 but present in 2016 get a growth rate of 3.4963 
# 3. stands present in 2010 but not present in 2016 get a loss of 81.8757 * hectarce / 6 
# 4. new stands in 2016, and loss in 2020 get low 13.9852 
### need to understand how the annual numbers are provided. 


changes1016 <- list.files(path = "data/products/areaMeasures",
                          pattern = "_1016.csv",
                          recursive = TRUE,
                          full.names = TRUE)

path <- changes1016[356]

applyMeasures <- function(path){
  # read in data 
  d1 <- read_csv(path) |>
    dplyr::mutate(
      existingMature = stable * 1.8463,
      newGrowth = gains * 3.4963,
      matureLoss = loss * 81.8757 / 6, 
      totalCarbonChange = existingMature + newGrowth - matureLoss
    )
  # grab name 
  name <- tools::file_path_sans_ext(basename(path))
  # export 
  write_csv(x = d1, file = paste0("data/products/carbonMeasures/",name,".csv"))
}

# render the measures 
purrr::map(.x = changes1016, applyMeasures)

### so could be able to run all 





###
# this does a lot... more of a workflow then a function, but rolling with it for now.... 
# The goal is to get a dataframe of  measured value in hectacres
calculateCarbonAreas <- function(grid, cotFiles, grids, crops){
  print(paste0("Starting process for ", grid))
  

  # select grid spatial layer 
  ## three layers one for each year 
  g1 <- grids |> terra::subset(grids$Unique_ID == grid) 
  g1 <- g1[1,]
  
  print("reading in layers")
  # read in change over time raster layer 
  raster <- cotFiles[grepl(pattern = paste0(grid,"_changeOverTime"), x = cotFiles)] |>
    terra::rast()
  # riparian 
  r1 <- raster$RiparianMask
  # trees 
  t1 <- raster$ChangeOverTime
  rm(raster)
  
  
  print("reclass")
  # generate the 5 raster files need
  ## takes about a minute... read to alter once we determine the 2016-2020 method as I don't think we will need all 5 reclasses 
  rasters <- reclassCOT(t1)
  

  # gather the total classified area for each year --------------------------
  dftotal <- data.frame(matrix(nrow = 3, ncol = 7))
  names(dftotal) <- c("id","type", "year", "growth", "stable", "gains", "loss")
  dftotal$id <- grid
  dftotal$year <- c("2010","2016","2020")
  dftotal$type <- "totalArea"
  dftotal$stable[1] <- freq(rasters$r10)$count[2]/10000
  dftotal$stable[2] <- freq(rasters$r16)$count[2]/10000
  dftotal$stable[3] <- freq(rasters$r20)$count[2]/10000
  
  
  # construct df to store values 
  ## this is what is returned 
  df1016 <- data.frame(matrix(nrow = 4, ncol = 7))
  names(df1016) <- c("id","type", "year", "growth", "stable", "gains", "loss")
  df1016$id <- grid
  df1016$year <- "2016"
  df1016$growth <- "mature"
  df1016$type <- c("all","riparian","crops","grass")
  
  
  
  # 2010-2016 measures 
  ## change the change measure in this format for comparison agianst 
  change <- rasters$r16 - rasters$r10
  stable <- rasters$r1016
  
  ### for change to 2016-2020 we need to know the combination of what's above. 
  ### see next section for values 
  

  # 2010-2016 workflow  -----------------------------------------------------
  print("all area counts")
  # assign values to storage dataframe 
  df1016 <-calArea(df = df1016, type = "all", stable = stable, change = change)
  

  # Process riparian  -------------------------------------------------------
  print("process riparian")
  # apply riparain mask 
  changeRiparain <- change * r1
  stableRiparian <- stable * r1 
  # assign values to storage dataframe 
  df1016 <-calArea(df = df1016,
               type = "riparian",
               stableRast = stableRiparian,
               changeRast = changeRiparain)
  

  # crops -------------------------------------------------------------------
  print("process crops")
  cropLayers <- processCropLayer(grid = g1, 
                                crops = crops, 
                                stable = stable, 
                                change = change,
                                year = "2016",
                                riparian = r1)
  # calculate areas 
  df1016 <-calArea(df = df1016, type = "crops", stableRast = cropLayers$stable, changeRast = cropLayers$change)
  
  # manually calculate the grass land option 
  print("process grass")
  df1016 <- calGrass(df1016)
  
  ## end of 2010-2015 work 
  
  

  # 2016 2020 work  ---------------------------------------------------------
  ## we need different measure for the 2016-2020 values based on if there is new grow or stable growth
  
  
  # 2020 new  ---------------------------------------------------------------
  new2016 <- terra::classify(change, rbind(c(-1, 0), c(1, 1)))
  ### I think we just run the 2020 stuff twice, once for new growth measures, onces for old 
  # construct df to store values 
  ## this is what is returned 
  df1620new <- data.frame(matrix(nrow = 4, ncol = 7))
  names(df1620new) <- c("id","type", "year", "growth", "stable", "gains", "loss")
  df1620new$id <- grid
  df1620new$year <- "2020"
  df1620new$growth <- "new"
  df1620new$type <- c("all","riparian","crops","grass")

  change <- rasters$r20 - new2016
  stable <- rasters$r1620
  
  
  print("all area counts")
  # assign values to storage dataframe 
  df1620new <-calArea(df = df1620new, type = "all", stable = stable, change = change)
  
  
  # Process riparian  -------------------------------------------------------
  print("process riparian")
  # apply riparain mask 
  changeRiparain <- change * r1
  stableRiparian <- stable * r1 
  # assign values to storage dataframe 
  df1620new <-calArea(df = df1620new,
               type = "riparian",
               stableRast = stableRiparian,
               changeRast = changeRiparain)
  
  
  # crops -------------------------------------------------------------------
  print("process crops")
  cropLayers <- processCropLayer(grid = g1, 
                                 crops = crops, 
                                 stable = stable, 
                                 change = change,
                                 year = "2020",
                                 riparian = r1)
  # calculate areas 
  df1620new <-calArea(df = df1620new, type = "crops", stableRast = cropLayers$stable, changeRast = cropLayers$change)
  
  # manually calculate the grass land option 
  print("process grass")
  df1620new <- calGrass(df1620new)
  
  

  # mature 2020 estimates  --------------------------------------------------
  ## define storage dataframe 
  df1620old<- data.frame(matrix(nrow = 4, ncol = 7))
  names(df1620old) <- c("id","type", "year", "growth", "stable", "gains", "loss")
  df1620old$id <- grid
  df1620old$year <- "2020"
  df1620old$growth <- "mature"
  df1620old$type <- c("all","riparian","crops","grass")
  
  change <- rasters$r20 - rasters$r1016  
  stable <- rasters$r1620
  
  
  print("all area counts")
  # assign values to storage dataframe 
  df1620old <-calArea(df = df1620old, type = "all", stable = stable, change = change)
  
  
  # Process riparian  -------------------------------------------------------
  print("process riparian")
  # apply riparain mask 
  changeRiparain <- change * r1
  stableRiparian <- stable * r1 
  # assign values to storage dataframe 
  df1620old <-calArea(df = df1620old,
                      type = "riparian",
                      stableRast = stableRiparian,
                      changeRast = changeRiparain)
  
  
  # crops -------------------------------------------------------------------
  print("process crops")
  cropLayers <- processCropLayer(grid = g1, 
                                 crops = crops, 
                                 stable = stable, 
                                 change = change,
                                 year = "2020",
                                 riparian = r1)
  # calculate areas 
  df1620old <-calArea(df = df1620old, type = "crops", stableRast = cropLayers$stable, changeRast = cropLayers$change)
  
  # manually calculate the grass land option 
  print("process grass")
  df1620old <- calGrass(df1620old)
  

  # combine all the dataframes  ---------------------------------------------
  df <- dftotal |>
    bind_rows(df1016) |>
    bind_rows(df1620new) |> 
    bind_rows(df1620old)

 return(df) 
}

vals <- c(paste0("X12-", c("100","200", "300", "400", "500", "600", "700")))

tic()
results <- purrr::map(.x = vals,.f = calculateCarbonAreas, 
                      cotFiles = cot,
                      grids = grids,
                      crops =  crops)
toc()
#