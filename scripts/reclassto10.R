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
# harmonized data
f2 <- files[grepl(pattern = "_harmonized", x = files)] 



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
### errors 336 "X12-413""X12-414""X12-415", "X12-592","X12-637",
### "X12-682","X12-725","X12-740","X12-766"
for(i in ids[767:773]){
  id <- i 
  f2 <- files[grepl(pattern = paste0(id,"_"), x = files)] 
  aggregateAndExport(id = id, paths = f2)
}


# harmonized adaptation  --------------------------------------------------

ids <- basename(f2)|>
  stringr::str_split(pattern = "_") |>
  lapply( function(feature) {
    if (length(feature) >= 1) {
      return(feature[[1]])
    } else {
      return(NA) # Or some other indicator if the feature doesn't have 6 elements
    }
  }) |> 
  unlist()|> 
  unique()



aggregateAndExportHarmonized <- function(path){
  # need 80% area for classificaiton 
  # all values >= 0 and <= 0.8 become 0
  # all values >= 0.8 and <= 1 become 1
  m <- c(0, 0.8, 0,
         0.8, 1, 1)
  rclmat <- matrix(m, ncol=3, byrow=TRUE)
  
  gridID <- stringr::str_split(basename(path), "_")[[1]][1]
  year <- stringr::str_split(path, "/")[[1]][3]
  
  # 2010
  if(year == "models2010"){
    file2010 <- paste0("data/products/tenMeterModels/tenMeter_",gridID,"_harmonized_2010.tif")
    if(!file.exists(file2010)){
      y10 <- terra::rast(path)|>
        terra::aggregate(fact = 10) |>
        terra::classify(rclmat)
      terra::writeRaster(x = y10, filename = file2010 )
    }
  }

  
  # 2016
  if(year == "models2016"){
    file2016 <- paste0("data/products/tenMeterModels/tenMeter_",gridID,"_harmonized_2016.tif")
    if(!file.exists(file2016)){
      y16 <- terra::rast(path)|>
        terra::aggregate(fact = 10) |>
        terra::classify(rclmat)
      terra::writeRaster(x = y16, filename = file2016)
    }
  }
  # 2020
  if(year == "models2020"){
    file2020 <- paste0("data/products/tenMeterModels/tenMeter_",gridID,"_harmonized_2020.tif")
    if(!file.exists(file2020)){
      y20 <- terra::rast(path)|>
        terra::aggregate(fact = 10) |>
        terra::classify(rclmat)
      terra::writeRaster(x = y20, filename = file2020)
    }
  }
}

# call funciton 
for(i in seq_along(f2)){
  print(i)
  aggregateAndExportHarmonized(path = f2[i])
}












