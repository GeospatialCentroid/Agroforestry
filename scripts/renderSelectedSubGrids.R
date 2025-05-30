pacman::p_load(terra,sf, readr, dplyr, tmap, furrr)
tmap_mode("view")

# read in refernce data 
d10 <- read_csv("data/products/selectedSubGrids/selections_2010.csv")
d16 <- read_csv("data/products/selectedSubGrids/selections_2010.csv")
d20 <- read_csv("data/products/selectedSubGrids/selections_2010.csv")
allGrids <- bind_rows(d10,d16,d20)
write_csv(x = allGrids, file = "data/products/selectedSubGrids/allSelectedGrids.csv")
# read in grid objects 
m2 <- sf::st_read("data/products/two_sq_grid.gpkg") |> 
  dplyr::select(FID_two_grid)
grid12 <- sf::st_read("data/processed/griddedFeatures/twelve_mi_grid_uid.gpkg")

# function for producing Imagery 
data <- d10
year <- "2010"
produce2MileImages <- function(data, year, m2, grid12){
  # for each 2m grid id 
  for(model in data$model){
    d1 <- data[data$model == model, ]
    print(model)

    for(grid in c("grid1", "grid2", "grid3", "grid4")){
      # select 2m grid id
      id2 <- d1[,grid] |> pull()
      #export path 
      exportPath <- paste0("data/products/selectedSubGrids/", model, "_subGrid_", id2,"_year_", year,".tif")
      if(!file.exists(exportPath)){
        # select 2 mile grid object 
        g2 <- m2[m2$FID_two_grid == id2, ]
        # centroid 
        centroid <- sf::st_centroid(g2)
        # extract 12 mile grid 
        g12 <- st_intersection(x = centroid, y = grid12) 
        id12 <- g12$Unique_ID
        # construct path 
        rast <- terra::rast(paste0("data/products/models",year,"/maskedImages/",id12,"_Masked.tif"))
        # crop to two mile grid 
        r1 <- terra::crop(rast, vect(g2))
        # export 
        terra::writeRaster(x = r1, filename = exportPath)
      }
    }
  }
}

plan(strategy = "multicore", workers = 3) 
furrr::future_map2(.x = list(d10,d16,d20), .y = c("2010","2016","2020"), .f = produce2MileImages,
                   m2 = m2,
                   grid12 = grid12)
