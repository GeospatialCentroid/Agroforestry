# 

pacman::p_load(terra, sf, dplyr, googledrive, stringr)

# pull in the specific model grid elements 
modelGrids <- list.files(path = "data/products", pattern = "modelGrids", full.names = TRUE)

# list files from from google drive
images <- googledrive::drive_ls(path = "agroforestry",pattern = ".tif")  |>
  dplyr::filter(!grepl('validationGrid', name))|>
  dplyr::filter(!grepl('naipGrid', name))
  
# images2020 <- filteredImages |> dplyr::filter(!grepl('2020', name))
# images2016 <- filteredImages |> dplyr::filter(!grepl('2016', name))
# images2010 <- filteredImages |> dplyr::filter(!grepl('2010', name))

# year <- "2020"
# 
# modelGrid <- modelGrids[grepl(pattern = year, x = modelGrids)] |> terra::vect()
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

downloadFromDrive(year = "2020", images = images, modelGrids = modelGrids)
downloadFromDrive(year = "2016", images = images, modelGrids = modelGrids)
downloadFromDrive(year = "2010", images = images, modelGrids = modelGrids)


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
for(i in c("2010","2016","2020")){
  processToGrids(year = i, modelGrids = modelGrids)
  
}


  
  for(j in downloadedFiles){
    rast <- terra::rast(i)
    for(k in modelGrid2){
      g1 <- modelGrid[modelGrid$Unique_ID == j, ]
      r1 <- NA
      try(r1 <- terra::crop(x = rast, y = g1))
      if(class(r1) == "SpatRaster"){
        k2 <- stringr::str_split(i, pattern = "/")[[1]][4]
        n1 <- paste0(productsPath, "/", j, "_",k2)
        if(!file.exists(n1)){
          try(terra::writeRaster(x = r1, filename = n1))
        }
      }
    }
  }
  
  }


# filter the google drive elemetns for features wint 
for(i in modelGrids){
  imageSelected <- imagesYear[grepl(pattern = i, x = imagesYear$name),]
  gridSelect <- gridYear[gridYear$modelGrid == i, ]
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
  downloadedFiles <- list.files(downloadPath, pattern = i,full.names = TRUE )
  productsPath <- paste0(downloadPath, "/grids")
  
  for(k in downloadedFiles){
    rast <- terra::rast(k)
    for(l in gridSelect$Unique_ID){
      g1 <- gridSelect[gridSelect$Unique_ID == l, ]
      r1 <- NA
      try(r1 <- terra::crop(x = rast, y = g1))
      if(class(r1) == "SpatRaster"){
        k2 <- stringr::str_split(k, pattern = "/")[[1]][4]
        n1 <- paste0(productsPath, "/", l, "_",k2)
        if(!file.exists(n1)){
          try(terra::writeRaster(x = r1, filename = n1))
        }
      }
    }
  }
}

View(grids)
index <- imagesYear[imagesYear$name ]
imageSelected <- imagesYear |> dplyr::filter(grepl(modelGrids, name))

# test to see a specific file intersects with the objects 


# apply the masks 

# 