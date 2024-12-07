###
# functions for generating some change over time files 
#
#
### 

pacman::p_load(dplyr, terra, purrr, furrr, stringr)

readAndName<- function(year, name, files){
  f1 <- files[grepl(pattern = year, 
                    x = files)]
  r1 <- terra::rast(f1) 
  names(r1) <- name
  return(r1)
}


# rasters <- purrr::map2(.x = years, .y = names, .f = readAndName, files = files) |>
#   terra::rast()

# for processing 
## end up with 6 layers 3 riparian mask, 3 new value class 

pullFullRiparianMask <- function(rasterStack){
  
  # loop over each layer 
  for(i in seq_along(names(rasterStack))){
    print(i)
    # select
    r1 <- rasterStack[[i]]
    # this reclass made it so only areas where all three years were present were included #|>
    #   subst(NA, 0)|>
    #   subst(1, 0)
    # test for postion in the processing 
    if(i == 1){
      rMask <- r1
    }else{
      rMask <- rMask + r1
    }
    # reclassy the final object
    rMask <- ifel(rMask < 1, NA , 1)
  }
  names(rMask) <- "RiparianMask"
  return(rMask)
}


changeOvertimeReclass <- function(rasterStack){
  rasterStack
  #2010 
  ## 0-1 
  print("2010")
  r1 <- rasterStack[[1]]
  r1 <- subst(r1, NA, 0)
  r1 <- subst(r1, 2, 1)
  
  #2016
  ## 0-3
  print("2016")
  r2 <- rasterStack[[2]] |>
    subst(NA, 0)|>
    subst(2, 1)|>
    subst(1, 3)
  
  r2 <- ifel(r2 < 1, 0 , 3)
  
  
  #2020
  ## 0-5 
  print("2020")
  r3 <- rasterStack[[3]]|>
    subst(NA, 0)|>
    subst(2, 1)|>
    subst(1, 5)
  # combine
  sumLayers <- function(r1,r2,r3){
    r1+r2+r3
  }
  combined <- c(r1,r2,r3) |>
    terra::lapp(fun = sumLayers)
  names(combined) <-"ChangeOverTime"
  return(combined)
}

produceCombination <- function(rasterStack){
  print("generating Riparain Mask")
  riparianMask <- NA
  try(riparianMask <- pullFullRiparianMask(rasterStack))
  
  print("generating Change over time layer")
  changeOverTime <- NA
  try(changeOverTime <-changeOvertimeReclass(rasterStack))
  print("combining layers")
  r1 <- c(changeOverTime,riparianMask )
  return(r1)
}
# 
library(tictoc)
tic()
x12_115 <- produceCombination(rasterStack = rasters)
toc()
# 248 seconds to render. 


# produce the change over time data for all observations 
files <- list.files(path = "data/products", 
                    pattern = "_riparianClass.tif",
                    full.names = TRUE,
                    recursive = TRUE)

grids <- paste0("X12-", 1:773)


furrApply <- function(grid,files){
  exportfile <- paste0("data/products/changeOverTime/",grid,"_changeOverTime.tif")
  
  # forcing rewrite. 
  !file.exists(exportfile)
  if(TRUE){
    # set parameters
    files2 <- files[grepl(pattern = paste0(grid,"_"), x = files)]
    years <-  c("2010", "2016", "2020")
    names <- paste0("r_", years)
    
    # render raster Stack 
    rasters <- NA
    try(rasters <- purrr::map2(.x = years, .y = names, .f = readAndName, files = files2) |>
      terra::rast())
    if(class(rasters) == "SpatRaster"){
      # generate combination layer
      r1 <- produceCombination(rasterStack = rasters)
      #export
      terra::writeRaster(x = r1, 
                         filename = exportfile)
    }else{
      write.csv(x = data.frame(),file =  paste0("data/products/changeOverTime/",grid,"_errroredOut.csv"))
    }
  }else{
    print("file already exists")
  }
  rm(r1, rasters)
}


plan(multicore, workers = 3)

# # sequential 
# tic()
# purrr::map(.x = grids[86:89],.f = furrApply, files = files)
# toc()
# 685.112 sec elapsed


### some memory allocation issues with this at the moment. 
# tic()
furrr::future_map(.x = grids, .f = furrApply, files = files)
# toc()
# about 5 seconds for the set up of the multisession. maybe???
# < 383.191 sec elapsed with and error Error: external pointer is not valid


