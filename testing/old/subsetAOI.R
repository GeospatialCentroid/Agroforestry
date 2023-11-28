# aoiID <- "X12-10"
# aoiSF <- sf::st_read("data/griddedFeatures/twelve_mi_grid_uid.gpkg")


#' Subset AOI 
#'
#' @param aoiID : reference id for the sampling site  
#' @param aoiSF : the sf object containing the gird information 
#' @description
#' Generates a series of polygons within the aoi of interest these polygolns are 
#' small enough to handle direct download from GEE
#' 
#' @return SF object of 100 polygons 
subsetAOI <- function(aoiID, aoiSF){
    # select the grid feature of interest 
    grid <- aoiSF |> 
      dplyr::filter(Unique_ID == aoiID)
    # genererate a sub grid from the original features 
    g2 <- sf::st_make_grid(x = grid, n = 10)
    # return feature 
    return(g2)
}
# 
# pacman::p_load(dplyr,sf)
# 
# d1 <- subsetAOI(aoiID, aoiSF)
# sf::st_write(obj = d1, dsn = "data/griddedFeatures/subgrid_test.gpkg" )
