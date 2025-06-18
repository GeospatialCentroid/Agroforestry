pacman::p_load(reader, dplyr, sf, purrr, terra)

grids2016 <- sf::st_read("data/products/modelGrids_2016.gpkg")

# read in all carbon measures and appending them to the grid layer 
files <- list.files(path = "data/products",
                    pattern = "_Masked.tif",
                    recursive = TRUE,
                    full.names = TRUE)
# ids
ids <- grids2016$Unique_ID
# harmonized data 
# df <- read.csv("data/processed/combinedHaromized/topModelsPerGrid.csv")
# ids <- df$gridsToRework


# harmonized data
# f2 <- files[grepl(pattern = "_harmonized", x = files)]  


# id <- ids[1]
# paths <- files
# year <- "2010"
aggregateAndExport <- function(id, paths, year, overwrite = FALSE){
  # need 80% area for classificaiton 
  # all values >= 0 and <= 0.8 become 0
  # all values >= 0.8 and <= 1 become 1
  m <- c(0, 0.8, 0,
         0.8, 1, 1)
  rclmat <- matrix(m, ncol=3, byrow=TRUE)
  
  # subset paths to year
  paths <- paths[grepl(pattern = year, x = paths)]
  
  
  # paths
  path <- paths[grepl(pattern = paste0(id,"_"), x = paths)]
  if(length(path)== 2){
    path <- path[grepl(pattern = "_harmonized", x = path)]
  }
  if(length(path) >0 ){
    r1 <- rast(path)
    
    if(year == "2010"){
      file2010 <- paste0("data/products/tenMeterModels/tenMeter_",id,"_2010.tif")
      print(file2010)
      if(!file.exists(file2010) | overwrite == TRUE){
        y10 <- r1 |>
          terra::aggregate(fact = 10) |>
          terra::classify(rclmat)
        terra::writeRaster(x = y10, filename = file2010, overwrite = TRUE )
      }
    }
    
    if(year == "2016"){
      file2016 <- paste0("data/products/tenMeterModels/tenMeter_",id,"_2016.tif")
      print(file2016)
      if(!file.exists(file2016)| overwrite == TRUE){
      y16 <- r1 |>
        terra::aggregate(fact = 10) |>
        terra::classify(rclmat)
      terra::writeRaster(x = y16, filename = file2016, overwrite = TRUE )
      }
    }
    
    if(year == "2020"){
      file2020 <- paste0("data/products/tenMeterModels/tenMeter_",id,"_2020.tif")
      print(file2020)
      if(!file.exists(file2020)| overwrite == TRUE){
        y20 <- r1 |>
          terra::aggregate(fact = 10) |>
          terra::classify(rclmat)
        terra::writeRaster(x = y20, filename = file2020, overwrite = TRUE )
      }
    }
  }
}

# itorate through the process 
### errors 336 "X12-413""X12-414""X12-415", "X12-592","X12-637",
### "X12-682","X12-725","X12-740","X12-766"

# ids10 <- df |> dplyr::filter(year == 2010) |> dplyr::select(gridsToRework) |> pull()
# ids16 <- df |> dplyr::filter(year == 2016) |> dplyr::select(gridsToRework) |> pull()
# ids20 <- df |> dplyr::filter(year == 2020) |> dplyr::select(gridsToRework) |> pull()

for(i in seq_along(ids)){
  id <- ids[i]
  aggregateAndExport(id = id, paths = files, year = "2010", overwrite = TRUE)
  aggregateAndExport(id = id, paths = files, year = "2016", overwrite = TRUE)
  aggregateAndExport(id = id, paths = files, year = "2020", overwrite = TRUE)
}





