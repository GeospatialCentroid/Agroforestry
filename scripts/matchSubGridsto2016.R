
pacman::p_load(sf, dplyr, readr, tmap, furrr, readr, terra)
tmap_mode("view")
# read in models grids for specific years 
g10 <- sf::st_read("data/products/modelGrids_2010.gpkg")
g20 <- sf::st_read("data/products/modelGrids_2020.gpkg")
m2 <- sf::st_read("data/products/two_sq_grid.gpkg") |> 
  dplyr::select(FID_two_grid)



# collect for 2016 grids  -------------------------------------------------
sampleGrids <- read_csv("data/products/allSelectedGrids(temp_exportDC).csv")

# grid <- sampleGrids[1, ]
# year <- "2010"


collect4Grids2 <- function(grid, year, m2){
  # select the model grid
  if(year == "2010"){
    grid12 <- sf::st_read("data/products/modelGrids_2010.gpkg")
    files <- list.files("data/products/models2010/maskedImages", 
                        full.names = TRUE)
  }else{
    grid12 <- sf::st_read("data/products/modelGrids_2020.gpkg")
    files <- list.files("data/products/models2020/maskedImages", 
                        full.names = TRUE)
  }
  
  for(index in 2:5){
    # grab id 
    subID <- grid[,index]|>
      dplyr::pull()
    print(subID)
    # select feature 
    subGrid <- m2[m2$FID_two_grid == subID, ] 
    # intersection between two objects  
    overlap <- sf::st_intersection(grid12, subGrid)
    # pull larger if overlap is present 
    if(nrow(overlap)> 1){
      areas <- st_area(overlap) |> as.numeric()
      # index the biggest feature
      sel <- grepl(pattern = max(areas), areas)
      # go with the biggests 
      overlap <- overlap[sel, ]
    }
    # pull raster images 
    gridID <- overlap$Unique_ID
    modelGrid <- unique(overlap$modelGrid)
    # path 
    exportPath <- paste0("data/products/selectedSubGrids/ID_",
                         gridID,"_MG_",modelGrid,"_SG_",subID,"_year_",year,"_2016Match.tif")
    if(!file.exists(exportPath)){
      # raster 
      r1 <- terra::rast(files[grepl(pattern = paste0(gridID,"_M"), files)]) |>
        terra::crop(subGrid)
      # export 
      terra::writeRaster(r1, filename = exportPath)
    }
  }
}

# loop and run 
for(i in 1:nrow(sampleGrids)){
  collect4Grids2(grid = sampleGrids[i,], 
                 year = "2010",
                 m2 = m2)
  collect4Grids2(grid = sampleGrids[i,],
                 year = "2020",
                 m2 = m2)
}


