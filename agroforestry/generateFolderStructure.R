
# dataPath <- "~/GitHub/Agroforestry/data"

#' Generate Folders
#'
#' @param dataPath 
#' @description
#' Produces file folders for the training and validation data sets 
#' 
generateFolders <- function(dataPath){
  filePath <- paste0(dataPath,"/processed/griddedFeatures/twelve_mi_grid_uid.gpkg")
  
  # read in full grid 
  fullGrid <- sf::st_read(filePath)
  
  #produce a folder for all grid areas 
  uniqueGrids <- fullGrid$Unique_ID |>
    st_drop_geometry()
  
  # loop over grids and create folders 
  for(i in uniqueGrids){
    # define path
    folder1 <- paste0(dataPath,"/raw/", i)
    # test if it exist else create 
    if(!dir.exists(folder1)){
      dir.create(folder1)
    }else{
      print("file exists")
    }
  }
}

# generateFolders("~/GitHub/Agroforestry/data")
