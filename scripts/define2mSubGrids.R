


pacman::p_load(sf, dplyr, readr, tmap, furrr, readr, terra)
tmap_mode("view")
# read in models grids for specific years 
g10 <- sf::st_read("data/products/modelGrids_2010.gpkg")
g16 <- sf::st_read("data/products/modelGrids_2016.gpkg")
g20 <- sf::st_read("data/products/modelGrids_2020.gpkg")
m2 <- sf::st_read("data/products/two_sq_grid.gpkg") |> 
  dplyr::select(FID_two_grid)


# Original  ---------------------------------------------------------------
# assign original areas measures 
m2$originalArea <- as.numeric(sf::st_area(m2))
# set seed 
set.seed(1234)

grid <- g10
year <- "2010"
# function for generating sub grids 
collect4Grids <- function(grid, year, m2){
  print(class(grid))
  # select unique models
  models <- unique(grid$modelGrid)
  # remove NA 
  models <- models[!is.na(models)]
  # exclude these areas from the grid features 
  grid2 <- grid[!grid$Unique_ID %in% models,]
  # drop all NA model areas 
  grid2 <- grid2[!is.na(grid2$modelGrid), ]
  
  exportPath <- paste0("data/products/selectedSubGrids/selections_",year,".csv")
  if(!file.exists(exportPath)){
    # data storage 
    df <- data.frame(model = models, year = year, grid1 = NA, grid2 = NA, grid3 = NA, grid4 = NA )
    print(year)
    # for each model grid, select all areas where model has
    for( i in models){
      print(i)
      # select all model area grids 
      sGrids <- grid2[grid2$modelGrid == i, ]
      # intersect the 2 mile grid 
      for(j in 1:nrow(sGrids)){
        feat <- sGrids[j,]
        # grab all features inside of specific grid 
        s2 <- sf::st_crop(m2, feat) |>
          sf::st_make_valid()
        # test inside 
        inside <- st_within(x = s2, y = feat, sparse = FALSE)
        s3 <- s2[as.vector(inside), ]
        ids <- s3$FID_two_grid
        if(j == 1){
          subSelection <- ids
        }else{
          subSelection <- c(subSelection,ids)
        }
      }
      # randomly select four elements from the list 
      random_elements <- sample(subSelection, 4)
      df[df$model == i, 3:6] <- random_elements
    }
    # export df 
    write_csv(x = df, exportPath)
  }else{
    print("data generated for ")
    print(year)
  }

}


plan(strategy = "multicore", workers = 3) 
furrr::future_map2(.x = list(g10,g16,g20), .y = c("2010","2016","2020"), .f = collect4Grids,
                   m2 = m2)
# purrr::map2(.x = list(g10,g16,g20), .y = c("2010","2016","2020"), .f = collect4Grids,
#             m2 = m2)

