# 

pacman::p_load(terra, sf, dplyr, googledrive, stringr,purrr,furrr, tigris)

# pull in the specific model grid elements 
modelGrids <- list.files(path = "data/products", pattern = "modelGrids", full.names = TRUE)

# list files from from google drive
images <- googledrive::drive_ls(path = "agroforestry",pattern = ".tif")  |>
  dplyr::filter(!grepl('validationGrid', name))|>
  dplyr::filter(!grepl('naipGrid', name))
  
# images2020 <- filteredImages |> dplyr::filter(!grepl('2020', name))
# images2016 <- filteredImages |> dplyr::filter(!grepl('2016', name))
# images2010 <- filteredImages |> dplyr::filter(!grepl('2010', name))

year <- "2020"
# 
modelGrid <- modelGrids[grepl(pattern = year, x = modelGrids)] |> terra::vect()
# for each model grid test select all the included sub grid 




# download data from Drive function 

downloadFromDrive <- function(year, images, modelGrids){
  # select the grid of interest 
  modelGrid <- modelGrids[grepl(pattern = year, x = modelGrids)] |> terra::vect()
  
  # select images of interest 
  images2 <- images |> dplyr::filter(grepl(year, name))
  # get unique model grids 
  modelGrids <- unique(modelGrid$modelGrid)
  modelGrids <- modelGrids[!is.na(modelGrids)]
  
  # loop over each model grid 
  for(i in modelGrids){
    imageSelected <- images2[grepl(pattern = i, x = images2$name),]
    gridSelect <- modelGrid[modelGrid$modelGrid == i, ]
    downloadPath <- paste0("data/products/models",year)
    for(j in seq_along(imageSelected$id)){
      id <- imageSelected$id[j]
      name <- imageSelected$name[j]
      # try statement it to help with the overwrite conditions 
      try(
        image <- googledrive::drive_download(as_id(id),
                                             path = paste0(downloadPath,"/",name))
      )
    }
  }
} 

# apply the download function  --------------------------------------------

# downloadFromDrive(year = "2020", images = images, modelGrids = modelGrids)
# downloadFromDrive(year = "2016", images = images, modelGrids = modelGrids)
# downloadFromDrive(year = "2010", images = images, modelGrids = modelGrids)


# function for cropping models to grids 

processToGrids <- function(year, modelGrids){
  
  # select model grids 
  modelGrid <- modelGrids[grepl(pattern = year, x = modelGrids)] |> terra::vect()
  
  uniqueGrid <- unique(modelGrid$modelGrid)
  uniqueGrid <- uniqueGrid[!is.na(uniqueGrid)] 
  
  # set the file locations 
  downloadPath <- paste0("data/products/models",year)
  productsPath <- paste0(downloadPath, "/grids")
  
  for(i in uniqueGrid){
    downloadedFiles <- list.files(downloadPath, pattern = i,full.names = TRUE )
    # subset spatial feature 
    g1 <- modelGrid[modelGrid$modelGrid ==i, ]
    # gather all individual model grids 
    subGrids <- as.data.frame(g1) |>
      dplyr::select(Unique_ID) |>
      pull()
    # loop over each downloaded file and generate subgrid datasets 
    for(j in downloadedFiles){
      # read in the specific image 
      rast <- terra::rast(j)
      # gather the model output name
      k2 <- stringr::str_split(j, pattern = "/")[[1]][4]
      for(k in subGrids){
        g2 <- g1[g1$Unique_ID == k,]
        r1 <- NA
        # set file path to check for existing files 
        n1 <- paste0(productsPath, "/", k, "_",k2)
        if(!file.exists(n1)){
        try(r1 <- terra::crop(x = rast, y = g2))
        if(class(r1) == "SpatRaster"){
            try(terra::writeRaster(x = r1, filename = n1))
          }
        }
      }
    }
  } 
}


# Process all sub grid data  ----------------------------------------------
# for(i in c("2010","2016","2020")){
#   processToGrids(year = i, modelGrids = modelGrids)
#}
# didn't really test but I think it'll work 
# set session info 
# plan(multicore, workers = 12)
# furrr::future_map(.x = c("2010","2016","2020"), .f = processToGrids, modelGrids = modelGrids)


# Apply the masks and bind to full grid ------------------------------------
# read in mask layers 

nlcdMasks <- list.files("data/products/nlcd",pattern = ".gpkg", full.names = TRUE, recursive = TRUE)
# tccs <- nlcdMasks[grepl(pattern = "tcc", nlcdMasks)]
forests <- nlcdMasks[grepl(pattern = "forest", nlcdMasks)]
# urban areas 
urbanFiles <- list.files("data/products/censusData/", pattern = "*\\.shp", full.names = TRUE, recursive = TRUE )
urbanFiles2 <- urbanFiles[stringr::str_ends(string = urbanFiles, pattern = ".shp")]
# riparian zones 
## need to get this cropped to nebraska and out of the GDB file structure 
# st_layers("data/raw/Data/RiparianAreas.gdb")
# rp <- sf::st_read("data/raw/Data/RiparianAreas.gdb", layer = "fras_blk_usfs_riparian_areas_1")

# interatre
mergeClass <- function(listOfImages){
  if(length(listOfImages) ==2){
    # add the images 
    r3 <- rast(listOfImages[1]) + rast(listOfImages[2])
    r4 <- ifel(r3 <= 1, 0 , 1)
  }else{
    r4 <- rast(listOfImages[1])
  }
  return(r4)
}


generateFinalGridImages <- function(year, modelGrids, forests, urbanFiles2){
  modelFolder <- paste0("data/products/models",year)
  # get all models for a year 
  models <- list.files(paste0(modelFolder,"/grids"), full.names = TRUE)
  # select images for specific grid 
  grids <- terra::vect(modelGrids[grepl(pattern = year, x = modelGrids)])
  # Select the forest and urban layers
  forest <- terra::vect(forests[grepl(pattern = year, x = forests)]) |>
    terra::project("+init=EPSG:4326")
  urban <- terra::vect(urbanFiles2[grepl(pattern = year, x = urbanFiles2)])|>
    terra::project("+init=EPSG:4326")
  ## add the riparian layer once that is created 
  
  # select all unique grids 
  ids <- grids$Unique_ID
  # itorate over grids to produce outputs 
  for(i in ids[1:20]){
    allImages <- models[grepl(paste0("/",i,"_"), models)]
    gridName <- i 
    unmaskedPath <- paste0("data/products/models",year,"/fullImages/",gridName,"_fullUnMasked.tif")
    # if there are images 
    if(length(allImages) > 0){
      if(!file.exists(unmaskedPath)){
        origImages <- allImages[!grepl(pattern = "_b_", allImages )]
        for(j in seq_along(origImages)){
          print(origImages[j])
          print("producing model area")
          n1 <- basename(origImages[j]) |>
            str_split(pattern = "_") |> 
            unlist()
          n2 <- n1[3]
          # select all paths with this image name 
          r1 <- allImages[grepl(pattern = n2, x = allImages)]
          # generate rast object 
          r2 <- mergeClass(r1)
          if(j == 1){
            r3 <- r2
          }else{
            print(paste0("merging ", j))
            r3 <- merge(r3,r2)
          }
        }
        # set the name of the object 
        rastName <-  paste0(gridName,"_",year)
        names(r3) <-rastName
        # export 
          try(terra::writeRaster(x = r3, filename = unmaskedPath ))
        }else{
      r3 <- terra::rast(unmaskedPath)
      }
      # produce a mask object
      maskedPath <- paste0("data/products/models",year,"/maskedImages/",gridName,"_Masked.tif")
      if(!file.exists(maskedPath)){
        print("generating mask")
        #  nlcd tree mask 
        ## crop 
        f2 <-  forest |>
          crop(r3)
        
        if(nrow(f2)){
          r4 <- r3 |>
            terra::mask(f2, inverse = TRUE,updatevalue=NA)
        }else{
          r4 <- r3
        }
        
        # town mask 
        t2 <- urban |> 
          crop(r3)
        if(nrow(t2)!=0){
          print("removing town")
          r4 <- r4 |>
            terra::mask(t2, inverse = TRUE,updatevalue=NA)
        }
        # export the masked image 
        try(terra::writeRaster(x = r4, filename = maskedPath ))
      }
    }else{
      print(paste0("no image for ",i))
    }
  }
}

generateFinalGridImages(year = year, 
                        modelGrids = modelGrids,
                        forests = forests, 
                        urbanFiles2 = urbanFiles2)



models2010 <- list.files("data/products/models2010/grids", full.names = TRUE)
# test <- terra::rast(models2010[1])
 grid2010 <- terra::vect(modelGrids[1])

# Select the year 
forest2010 <- terra::vect(forests[grepl(pattern = "2010", x = forests)]) |>
  terra::project("+init=EPSG:4326")
urban2010 <- terra::vect(urbanFiles2[grepl(pattern = "2010", x = urbanFiles2)])|>
  terra::project("+init=EPSG:4326")

# itorate over the gridid 
year <- "2010"
ids <- grid2010$Unique_ID
i <- "X12-101"
# aggregate all images from a grid 
allImages <- models2010[grepl(paste0("/",i,"_"), models2010)]

# select all non b models 
origImages <- allImages[!grepl(pattern = "_b_", allImages )]



## reclass binary maps when two images exist 
## merge images if multiple grids exists 
for(i in seq_along(origImages)){
  print(origImages[i])
  n1 <- basename(origImages[i]) |>
    str_split(pattern = "_") |> 
    unlist()
  gridName <- n1[1]
  n2 <- n1[3]
  # select all paths with this image name 
  r1 <- allImages[grepl(pattern = n2, x = allImages)]
  # generate rast object 
  r2 <- mergeClass(r1)
  if(i == 1){
    r3 <- r2
  }else{
    print(paste0("merging ", i))
    r3 <- merge(r3,r2)
  }
}
# set the name of the object 
rastName <-  paste0(gridName,"_",year)
names(r3) <-rastName
# export 
terra::writeRaster(x = r3, filename = paste0("data/products/models",year,"/fullImages/",gridName,"_fullUnMasked.tif"))


#  nlcd tree mask 
## crop 
f2 <-  forest2010 |>
  crop(r3)

if(nrow(f2)){
  r4 <- r3 |>
    terra::mask(f2, inverse = TRUE,updatevalue=NA)
}else{
  r4 <- r3
}

# town mask 
t2 <- urban2010 |> 
  crop(r3)
if(nrow(t2)!=0){
  print("removing town")
  r4 <- r4 |>
    terra::mask(t2, inverse = TRUE,updatevalue=NA)
}
# export the masked image 
terra::writeRaster(x = r4, filename = paste0("data/products/models",year,"/maskedImages/",gridName,"_Masked.tif"))

# riparian classification 
## repreat this process with the town mask segment as well. 
# town mask 
# t2 <- urban2010 |> 
#   crop(r3)
# if(nrow(t2)!=0){
#   print("removing town")
#   r4 <- r4 |>
#     terra::mask(t2, inverse = TRUE,updatevalue=NA)
# }





