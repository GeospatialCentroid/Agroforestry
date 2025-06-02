
pacman::p_load(terra, sf, dplyr, googledrive,
               stringr,tmap)
tmap::tmap_mode("view")
# 
# # pull in the specific model grid elements 
# modelGrids <- list.files(path = "data/products", pattern = "modelGrids", full.names = TRUE)
# # list files from from google drive
# images <- googledrive::drive_ls(path = "agroforestry",pattern = ".tif")  |>
#   dplyr::filter(!grepl('validationGrid', name))|>
#   dplyr::filter(!grepl('naipGrid', name))
# 



# year <- "2020"
# 
# modelGrid <- modelGrids[grepl(pattern = year, x = modelGrids)] |> terra::vect()
# for each model grid test select all the included sub grid 


# download validataion from drive 
downloadValidationFromDrive <- function(run = FALSE){
  if(run == TRUE){
    # grab all images 
    validataionImages <- googledrive::drive_ls(path = as_id("https://drive.google.com/drive/u/0/folders/1QP6xpwwQSP1paTnsxjdWThy1qFqfuXvg"),
                                               pattern = "_subgrid_",
                                               recursive = TRUE
    ) 
    # 
    exportPath <- "data/products/selectedSubGrids/NAIP"
    for(j in seq_along(validataionImages$id)){
      id <- validataionImages$id[j]
      name <- validataionImages$name[j]
      exportName <- paste0(exportPath,"/naip_",name)
      if(!file.exists(exportName)){
        
        # try statement it to help with the overwrite conditions 
        try(
          image <- googledrive::drive_download(as_id(id),
                                               path = exportName,
                                               overwrite = FALSE)
        )
      }
    }
  }
}
# pull 2mile NAIP validataion imagery 
downloadValidationFromDrive(run = FALSE)
  
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
  for(i in modelGrids[1:10]){
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

# downloadFromDrive(year = "2020", images = images2020, modelGrids = modelGrids)
# downloadFromDrive(year = "2016", images = images, modelGrids = modelGrids)
# downloadFromDrive(year = "2010", images = images, modelGrids = modelGrids)
