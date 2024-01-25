# library(sf)
# library(tmap)
# tmap_mode("view")
# t2 <- sftmapt2 <- sf::st_read("~/GitHub/Agroforestry/data/processed/griddedFeatures/twelve_mi_grid_uid.gpkg")
# 
# gridID <- "X12-601"


defineNeighborGrid <- function(gridID, dataPath){
  # set file path
  filePath <- paste0(dataPath,"/processed/griddedFeatures/twelve_mi_grid_uid.gpkg")

    # read in full grid 
  fullGrid <- sf::st_read(filePath)
  
  # define export location 
  # exportPath <- paste0(dataPath, "/processed/", gridID)s
  
  # sub set unique grid
  startGrid <- fullGrid |>
    dplyr::filter(Unique_ID == gridID)
  
  
  # 8 features 
  # intersect with full grid feature 
  inter1 <- st_intersects(fullGrid,startGrid, sparse = FALSE)
  # select specific features of interest
  g8 <- fullGrid[inter1[,1],]
  ## pull all of those grid ids and store 
  df <- g8 |>
    st_drop_geometry()|>
    dplyr::select(Unique_ID)|>
    dplyr::mutate(poisition = 1)
  
  
  # 16 features 
  # st_union to create a  larger polygon of all features 
  g8_disolveed <- st_union(x = g8)
  # intersect with full grid feature 
  inter8 <- st_intersects(fullGrid,g8_disolveed, sparse = FALSE)
  g16 <- fullGrid[inter8[,1],]
  ## pull all of those grid ids and store 
  df2 <- g16 |>
    st_drop_geometry()|>
    dplyr::select(Unique_ID)|>
    dplyr::mutate(poisition = 2)|>
    dplyr::filter(!Unique_ID %in% df$Unique_ID)
  # bind data
  df <- dplyr::bind_rows(df,df2)
  
  
  # 24 features
  # st_union to create a  larger polygon of all features 
  g16_disolveed <- st_union(x = g16)
  # intersect with full grid feature 
  inter16 <- st_intersects(fullGrid,g16_disolveed, sparse = FALSE)
  g24 <- fullGrid[inter16[,1],]
  ## pull all of those grid ids and store 
  df3 <- g24 |>
    st_drop_geometry()|>
    dplyr::select(Unique_ID)|>
    dplyr::mutate(poisition = 3)|>
    dplyr::filter(!Unique_ID %in% df$Unique_ID)
  # bind data
  df <- dplyr::bind_rows(df,df3)
  
  
  # 32 features 
  # st_union to create a  larger polygon of all features 
  g24_disolveed <- st_union(x = g24)
  # intersect with full grid feature 
  inter24 <- st_intersects(fullGrid,g24_disolveed, sparse = FALSE)
  g32 <- fullGrid[inter24[,1],]
  ## pull all of those grid ids and store 
  df4 <- g32 |>
    st_drop_geometry()|>
    dplyr::select(Unique_ID)|>
    dplyr::mutate(poisition = 3)|>
    dplyr::filter(!Unique_ID %in% df$Unique_ID)
  # bind data
  df <- dplyr::bind_rows(df,df4)
  
  
  # return a dataframe with grid id and the number of positions away from the center 
  return(df)
  # write.csv(df, file = paste0(exportPath, "/neighborGrids.csv") )
}



