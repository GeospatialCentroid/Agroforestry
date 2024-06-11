# 

pacman::p_load(terra, sf, dplyr, googledrive, stringr)

# pull in the specific model grid elements 
grids <- list.files(path = "data/products", pattern = "modelGrids", full.names = TRUE)

# list files from from google drive
images <- googledrive::drive_ls(path = "agroforestry",pattern = ".tif") 
filteredImages <- images |>
  dplyr::filter(!grepl('validationGrid', name))|>
  dplyr::filter(!grepl('naipGrid', name))
  
images2020 <- filteredImages |> dplyr::filter(!grepl('2020', name))
images2016 <- filteredImages |> dplyr::filter(!grepl('2016', name))
images2010 <- filteredImages |> dplyr::filter(!grepl('2010', name))

year <- "2020"
imagesYear <- filteredImages |> dplyr::filter(grepl(paste0(year,"model"), name))
gridYear <- grids[grepl(pattern = year, x = grids)] |> terra::vect()
# for each model grid test select all the included sub grid 

modelGrids <- unique(gridYear$modelGrid)
# filter the google drive elemetns for features wint 
for(i in modelGrids){
  imageSelected <- imagesYear[grepl(pattern = i, x = imagesYear$name),]
  gridSelect <- gridYear[gridYear$modelGrid == i, ]
  downloadPath <- paste0("data/products/models",year,"/")
  for(j in seq_along(imageSelected$id)){
    id <- imageSelected$id[j]
    name <- imageSelected$name[j]
    # try statement it to help with the overwrite conditions 
    try(
    image <- googledrive::drive_download(as_id(id),
                                               path = paste0(downloadPath,name))
    )
  }
  downloadedFiles <- list.files(downloadPath, pattern = i,full.names = TRUE )
  productsPath <- paste0(downloadPath, "grids")
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