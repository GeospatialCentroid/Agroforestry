###
# functions for generating some change over time files 
#
#
### 

pacman::p_load(dplyr, terra, purrr, furrr, stringr)

files <- list.files(path = "data/products", 
                    pattern = "_riparianClass.tif",
                    full.names = TRUE,
                    recursive = TRUE)

hFiles <- files[grepl("_harmonized", x = files)]
hGrids <- paste0("X12-", c(318,319,366,367,413))
grids <- paste0("X12-", 1:773)

# errors from maps 
areaFiles <- list.files(
  path = "~/trueNAS/work/agroforestrySampling/data/derived/areaCounts/fullState",
  full.names = TRUE
)

test <- paste0(grids,".csv")
rerun <- c()
for(i in seq_along(test)){
  id <- test[i]
  g <- grids[i]
  presence <- grepl(pattern = id, x = areaFiles)
  if(!TRUE %in% presence){
    rerun <- append(rerun, g)
  }
}
# use this to remove cot files 


readAndName<- function(year, name, files){
  f1 <- files[grepl(pattern = year, 
                    x = files)]
  r1 <- terra::rast(f1) 
  names(r1) <- name
  return(r1)
}


# clean up process --------------------------------------------------------
## rewrite the change over time classification process 
### select all _Masked.tif for grid 
### select final ripairan mask 
### reclass masked images by year 
### sum features 
### append riparian 

maskedFiles <- list.files(path = "data/products", 
                             pattern = "_Masked.tif",
                             full.names = TRUE,
                             recursive = TRUE)

riparianFiles <- list.files(path = "data/products/riparian/allYears", 
                          pattern = ".tif",
                          full.names = TRUE)
gridId <- grids[336]
produceCOT <- function(gridID, maskedFiles, riparianFiles){
  # select all _Masked images 
  masked <- maskedFiles[grepl(pattern = paste0(gridID, "_Masked"), maskedFiles)]
  if(length(masked) != 3){
    print("Missing masked model")
    stop()
  }
  # select the riparian feature 
  rip <- riparianFiles[grepl(pattern = paste0(gridID, ".tif"), riparianFiles)]
  if(length(rip) != 1){
    print("missing riparian output")
    stop()
  }else{
    r1 <- rast(rip)
  }
  # reclass masked images by year 
  r10 <- masked[grepl(pattern = "models2010", masked)]|>
    terra::rast()
  names(r10) <- "r10"
  r16 <- masked[grepl(pattern = "models2016", masked)]|>
    terra::rast()|>
    terra::subst(from = 1, to = 3)
  names(r16) <- "r16"
  r20 <- masked[grepl(pattern = "models2020", masked)]|>
    terra::rast()|>
    terra::subst(from = 1, to = 5)
  names(r20) <- "r20"
  # some minor ext mismatching so test area and crop to the smallest 
  areas <- c(ncell(r10),ncell(r16),ncell(r20)) 
  names(areas) <- c("r10","r16","r20")
  if(length(unique(areas))>1){
    t1 <- min(areas)
    # select the feature that has min value 
    min <- areas[grepl(pattern = t1, x = areas)] |> names()
    # condition for the crop 
    if(min[1] == "r10"){
      r16 <- crop(r16,r10)
      r20 <- crop(r20,r10)
      r1 <- crop(r1, r10)
    }
    if(min[1] == "r16"){
      r10 <- crop(r10,r16)
      r20 <- crop(r20,r16)
      r1 <- crop(r1, r16)
    }
    if(min[1] == "r20"){
      r10 <- crop(r10,r20)
      r16 <- crop(r16,r20)
      r1 <- crop(r1, r20)
    }
  }
  # sum features 
  cot <- r10 + r16 + r20
  # crop just because 
  r1 <- terra::crop(r1, cot)
  # add the riparian layer 
  cot <- c(cot, r1 )
  names(cot)<-c("ChangeOverTime", "RiparianMask")
  rm(r10,r16,r20,r1)
  gc()
  return(cot)
}


# apply COT  --------------------------------------------------------------
## some cases where COT layers have 4 features will check and delete if present 
cots <- list.files(path = "data/products/changeOverTime",
                   full.names = TRUE,
                   pattern = "_2.tif")
# remove some of these files based on 
# for(i in rerun){
#   t1 <- cots[grepl(paste0(i,"_"), cots)]
#   file.remove(t1)
# }

## quick read and remove if 4 features are present 
for(i in cots){
  r1 <- terra::rast(i)
  if(length(names(r1))>2){
    print(i)
    file.remove(i)
  }
}

# apply the change over time method 
# 336 missing riparian layer 
for(i in 1:length(grids)){
  # select grid 
  grid <- grids[i]
  # export path 
  exportPath <- paste0("data/products/changeOverTime/",grid,"_changeOverTime_2.tif")
  #test for presence 
  if(!file.exists(exportPath)){
    print(grid)
    # rended the cot file 
    cot <- produceCOT(gridID = grid,
                      maskedFiles = maskedFiles,
                      riparianFiles = riparianFiles)
    # export 
    terra::writeRaster(x = cot, filename = exportPath)
  }
}



# original  ---------------------------------------------------------------



# # 
# rasters <- purrr::map2(.x = years, .y = names, .f = readAndName, files = files) |>
#   terra::rast()

# remove all files that were effected by harmonization 
df <- read.csv("data/processed/harmonizedImages/gridsToRework.csv")
uniqueGrids <- unique(df$gridsToRework)
for(i in uniqueGrids){
  # f1 <- paste0("data/products/riparian/allYears/riparianMask_",i,".tif")
  # try(file.remove(f1))
  f2 <- paste0("data/products/changeOverTime/",i,"_changeOverTime_2.tif")
  try(file.remove(f2))
}
# remove all files that have had new models added 
correctedGrid <- unique(c("X12-1","X12-2","X12-3","X12-4","X12-5","X12-6", 
  "X12-7","X12-336", "X12-414", "X12-415", "X12-592", "X12-637",
  "X12-682","X12-725","X12-740","X12-766","X12-336","X12-414","X12-415",
  "X12-592","X12-637", "X12-682","X12-725", "X12-740", "X12-766"))
for(i in correctedGrid){
  # f1 <- paste0("data/products/riparian/allYears/riparianMask_",i,".tif")
  # try(file.remove(f1))
  f2 <- paste0("data/products/changeOverTime/",i,"_changeOverTime_2.tif")
  try(file.remove(f2))
}




# 12-2024 update, add riparian data back to models ------------------------
## I had to regenerate the riparian layer so that is capture all areas predicted 
## as trees for each individual model year. This is me appending them to the COT rasters 
models <- list.files(path = "data/products/changeOverTime", 
                     pattern = ".tif",
                     full.names = TRUE)
newRip <- list.files(path = "data/products/riparian/allYears", 
                     pattern = ".tif",
                     full.names = TRUE)
grids <- paste0("X12-", 1:773)


appendRiparian <- function(grid, models, newRip){
  print(grid)
  
  newFile <- paste0("data/products/changeOverTime/",grid,"_changeOverTime_2.tif")
  if(!file.exists(newFile)){
    # define some placeholder variables 
    model <- NA
    riparian <- NA
    # test for model presence 
    f1 <- models[grepl(pattern = paste0(grid,"_"), x = models)]
    if(length(f1) != 0){
      # read in data 
      model <- terra::rast(f1)
    }
    # test for riparian layer 
    f2 <- newRip[grepl(pattern = paste0(grid,".tif"), x = newRip)]
    if(length(f2) != 0){
      # read in data 
      riparian <- terra::rast(f2)
    }
    # if both are present combine 
    if(class(model) == "SpatRaster" & class(riparian) == "SpatRaster"){
      # assign value
      model$RiparianMask <- riparian
      # export
      terra::writeRaster(x = model,
                         filename = newFile,
                         overwrite= TRUE )
    }else{
      print("no output created")
    }
  }else{
    print("File exists")
  }
}

for(i in grids){
  appendRiparian(grid = i, models = models, newRip = newRip)
}

# trying furrr implimentation 
plan(multicore, workers = 4)

### some memory allocation issues with this at the moment. 
tic()
furrr::future_map(.x = grids[11:15], .f = appendRiparian, models = models,
                  newRip = newRip)
toc()

### need to change this to reading in dataset then exporting 


changeOvertimeReclass <- function(rasterStack){
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
  if(!file.exists(exportfile)){
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


plan(multicore, workers = 2)

# # sequential 
# tic()
purrr::map(.x = grids,.f = furrApply, files = files)
# toc()
# 685.112 sec elapsed





### some memory allocation issues with this at the moment. 
# tic()
furrr::future_map(.x = grids, .f = furrApply, files = files)
# toc()
# about 5 seconds for the set up of the multisession. maybe???
# < 383.191 sec elapsed with and error Error: external pointer is not valid





# edits for Harmonized images  --------------------------------------------

files <- list.files(path = "data/products", 
                    pattern = "_riparianClass.tif",
                    full.names = TRUE,
                    recursive = TRUE)

hFiles <- files[grepl("_harmonized", x = files)]
basenames <- basename(hFiles) |>
  stringr::str_split( pattern = "_")
hGrids <- lapply(basenames, function(feature) {
  if (length(feature) >= 2) {
    return(feature[[1]])
  } else {
    return(NA) # Or some other indicator if the feature doesn't have 6 elements
  }
}) |> unlist()|> unique()

# remove all previous harmized files 
# remove <- files[grepl(pattern = "2010", x = files)]
# remove2 <- remove[!grepl(pattern = "harmonized", x = remove)]
# for(i in hGrids){
#   # test for grid match 
#   sel <- remove2[grepl(pattern = i, x = remove2)] 
#   if(length(sel) != 0){
#     file.remove(sel)
#   }
# }



# for processing 

renderFullRiparianMask <- function(grid, files){
  
  exportPath <- paste0("data/products/riparian/allYears/riparianMask_harmonized_",grid,".tif")
  print(grid)
  if(!file.exists(exportPath)){
    # filter and read in images 
    f1 <- files[grepl(pattern = paste0(grid,"_"), x = files)]
    # not sure how to best hand this step I think for now just include all riparian layers
    if(length(f1) > 0){
      
      # reclass function 1 
      reclas <- function(raster){
        ifel(raster == 2, 1 , 0)
      }
      # gather and reclass layers 
      r1 <- lapply(X = f1, FUN = terra::rast) |>
        purrr::map(.f = reclas)
      # add them all together
      ## 318 has some issues with different resolution 
      r2 <- terra::app(x = terra::rast(r1), fun = sum, na.rm = TRUE)
      # reclass and export
      r3 <- terra::ifel(r2 >0, 1 , NA)
      terra::writeRaster(x = r3, filename = exportPath)
    }
  }
  gc()
}




# render riparian  --------------------------------------------------------
print("generating Riparain Mask")
tic()
purrr::map(.x = grids[4], .f = renderFullRiparianMask, files = files)
toc()

future::availableCores()
plan(multicore)
tic()
furrr::future_map(.x = grids, .f = renderFullRiparianMask, files = files)
toc()


# 12-2024 update, add riparian data back to models ------------------------
## I had to regenerate the riparian layer so that is capture all areas predicted 
## as trees for each individual model year. This is me appending them to the COT rasters 
models <- list.files(path = "data/products/changeOverTime", 
                     pattern = ".tif",
                     full.names = TRUE)
newRip <- list.files(path = "data/products/riparian/allYears", 
                     pattern = ".tif",
                     full.names = TRUE)
grids <- paste0("X12-", 1:773)


appendRiparian <- function(grid, models, newRip){
  print(grid)
  
  newFile <- paste0("data/products/changeOverTime/",grid,"_changeOverTime_2.tif")
  if(!file.exists(newFile)){
    # define some placeholder variables 
    model <- NA
    riparian <- NA
    # test for model presence 
    f1 <- models[grepl(pattern = paste0(grid,"_"), x = models)]
    if(length(f1) != 0){
      # read in data 
      model <- terra::rast(f1)
    }
    # test for riparian layer 
    f2 <- newRip[grepl(pattern = paste0(grid,".tif"), x = newRip)]
    if(length(f2) != 0){
      # read in data 
      riparian <- terra::rast(f2)
    }
    # if both are present combine 
    if(class(model) == "SpatRaster" & class(riparian) == "SpatRaster"){
      # assign value
      model$RiparianMask <- riparian
      # export
      terra::writeRaster(x = model,
                         filename = newFile,
                         overwrite= TRUE )
    }else{
      print("no output created")
    }
  }else{
    print("File exists")
  }
}

for(i in grids){
  appendRiparian(grid = i, models = models, newRip = newRip)
}

# trying furrr implimentation 
plan(multicore, workers = 4)

### some memory allocation issues with this at the moment. 
tic()
furrr::future_map(.x = grids[11:15], .f = appendRiparian, models = models,
                  newRip = newRip)
toc()

### need to change this to reading in dataset then exporting 


changeOvertimeReclass <- function(rasterStack){
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


plan(multicore, workers = 2)

# # sequential 
# tic()
purrr::map(.x = grids,.f = furrApply, files = files)
# toc()
# 685.112 sec elapsed





### some memory allocation issues with this at the moment. 
# tic()
furrr::future_map(.x = grids, .f = furrApply, files = files)
# toc()
# about 5 seconds for the set up of the multisession. maybe???
# < 383.191 sec elapsed with and error Error: external pointer is not valid



