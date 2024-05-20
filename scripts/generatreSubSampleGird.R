# grab the organized model layers 
# determine the total number of 12m grids on the map 
# sample randomly across those grids excluding the grid which was used for training
# use those selected grid to pull a 2mile grid that is within the bounds 

# library
library(terra)
library(dplyr)
library(sf)

# datasets 
grid2020 <- terra::vect("data/products/modelGrids_2020.gpkg")
grid2016 <- terra::vect("data/products/modelGrids_2016.gpkg")
grid2010 <- terra::vect("data/products/modelGrids_2010.gpkg")
grid12m <- terra::vect("data/processed/griddedFeatures/twelve_mi_grid_uid.gpkg")
grid2m  <- terra::vect("data/processed/griddedFeatures/two_sq_grid.gpkg") 
# drop extra info
grid2m <- grid2m[,1:2]



produceSampleGrids <- function(grid, grid12m, grid2m, year){
  # summarize the number of locations per model grid 
  d1 <- grid |>
    terra::as.data.frame() |>
    dplyr::group_by(modelGrid) |>
    dplyr::summarise(count = n(), score = mean(score)) 
  d1 <- d1[!is.na(d1$modelGrid),]
  #export
  file1 <- paste0("data/products/samplingAreas/areaCounts_",year,".csv")
  write.csv(x = d1,file = file1 )
  # probably an export here as this will inform our sampling approach 
  uniqueGrids <- d1$modelGrid
  subGrids <- as.data.frame(matrix(nrow = length(uniqueGrids),ncol = 2))
  names(subGrids) <- c("modelGrid", "grid2m")
  
  for(i in 1:length(uniqueGrids)){
    print(i)
    gridID <- uniqueGrids[i]
    # select all model grids
    grid2 <- subset(grid, grid$modelGrid == gridID)
    grid3 <- subset(grid2, grid2$Unique_ID != gridID)  |>
      aggregate()
    # mask the 2m grid to the aoi
    
    g4 <- grid2m |>
      terra::crop(grid3)
    g4$area <- expanse(g4)
    # subset to includes only full areas 
    g5 <- g4[g4$area >= 7000000, ] # hard coded value might cause some isses...
    ### alternative is bringin in sf and fitering to the features that st_within
    # within <- st_within(x = st_as_sf(g4), y = st_as_sf(grid3),sparse = TRUE)
    ## 
    selectedGrid <- sample(x = g5$FID_two_grid, size = 1)
    # # assign values 
    subGrids$modelGrid[i] <- gridID
    subGrids$grid2m[i] <- selectedGrid
  }
  #export
  file2 <- paste0("data/products/samplingAreas/2mSampleGrids_",year,".csv")
  write.csv(x = subGrids,file = file2 ) 
}

# 2020
produceSampleGrids(grid = grid2020,
                   grid12m = grid12m,
                   grid2m = grid2m,
                   year = 2020)
# 2016
produceSampleGrids(grid = grid2016,
                   grid12m = grid12m,
                   grid2m = grid2m,
                   year = 2016)
# 2010
produceSampleGrids(grid = grid2010,
                   grid12m = grid12m,
                   grid2m = grid2m,
                   year = 2010)




