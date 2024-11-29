pacman::p_load(reader, dplyr, sf, purrr)

grids2016 <- sf::st_read("data/products/modelGrids_2016.gpkg")

# read in all carbon measures and appending them to the grid layer 
files <- list.files(path = "data/products",
                    pattern = "_Masked.tif",
                    recursive = TRUE,
                    full.names = TRUE)
# ids
ids <- grids2016$Unique_ID


# for each id reclass to 10 
f2 <- files[grepl(pattern = paste0(id,"_"), x = files)] 


id <- id 
paths <- f2
aggregateAndExport <- function(id, paths){
  # need 80% area for classificaiton 
  # all values >= 0 and <= 0.8 become 0
  # all values >= 0.8 and <= 1 become 1
  m <- c(0, 0.8, 0,
         0.8, 1, 1)
  rclmat <- matrix(m, ncol=3, byrow=TRUE)
  
  # 2010
  file2010 <- paste0("data/products/tenMeterModels/tenMeter_",id,"_2010.tif")
  if(!file.exists(file2010)){
    y10 <- terra::rast(f2[grepl(pattern = "models2010", f2)])|>
      terra::aggregate(fact = 10) |>
      terra::classify(rclmat)
    terra::writeRaster(x = y10, filename = file2010 )
  }

  # 2016
  file2016 <- paste0("data/products/tenMeterModels/tenMeter_",id,"_2016.tif")

  if(!file.exists(file2016)){
    y16 <- terra::rast(f2[grepl(pattern = "models2016", f2)])|>
    terra::aggregate(fact = 10) |>
    terra::classify(rclmat)
    terra::writeRaster(x = y16, filename = file2016)
  }
  # 2020
  file2020 <- paste0("data/products/tenMeterModels/tenMeter_",id,"_2020.tif")
  if(!file.exists(file2020)){
    y20 <- terra::rast(f2[grepl(pattern = "models2020", f2)])|>
      terra::aggregate(fact = 10) |>
      terra::classify(rclmat)
    terra::writeRaster(x = y20, filename = file2020)
  }
  rm(y10,y16,y20)
}

# itorate through the process 
### errors 336 "X12-413""X12-414""X12-415", "X12-592"
for(i in ids[638:773]){
  id <- i 
  f2 <- files[grepl(pattern = paste0(id,"_"), x = files)] 
  aggregateAndExport(id = id, paths = f2)
}

