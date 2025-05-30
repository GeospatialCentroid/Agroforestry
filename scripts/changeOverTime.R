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

# hFiles <- files[grepl("_harmonized", x = files)]
# hGrids <- paste0("X12-", c(318,319,366,367,413))
grids <- paste0("X12-", 1:773)

# errors from maps 
# areaFiles <- list.files(
#   path = "~/trueNAS/work/agroforestrySampling/data/derived/areaCounts/fullState",
#   full.names = TRUE
# )

# test <- paste0(grids,".csv")
# rerun <- c()
# for(i in seq_along(test)){
#   id <- test[i]
#   g <- grids[i]
#   presence <- grepl(pattern = id, x = areaFiles)
#   if(!TRUE %in% presence){
#     rerun <- append(rerun, g)
#   }
# }
# use this to remove cot files 


# readAndName<- function(year, name, files){
#   f1 <- files[grepl(pattern = year, 
#                     x = files)]
#   r1 <- terra::rast(f1) 
#   names(r1) <- name
#   return(r1)
# }
# 

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
gridID <- grids[319]
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
# for(i in cots){
#   r1 <- terra::rast(i)
#   if(length(names(r1))>2){
#     print(i)
#     file.remove(i)
#   }
# }

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

