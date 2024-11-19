# temp function for assigning a current score 
assignScore <- function(data){
  # get the unique model grids 
  uniqueModels <- unique(data$modelGrid)
  # generate a template score value 
  scores <- runif(length(uniqueModels), min=0.1, max=0.6)
  # assign a score value 
  data$validationScore <- NA 
  for(i in seq_along(uniqueModels)){
    id <- uniqueModels[i]
    val <- scores[i]
    index <- data$modelGrid == id 
    data$validationScore[index] <- val
  }
  return(data)
}


# reclass rasters  --------------------------------------------------------
reclass1016 <- function(raster){
  # 2010 only 
  m <- rbind(c(0, 0),
             c(1, 1),
             c(3, 0),
             c(4, 1),
             c(5, 0),
             c(6, 1),
             c(8, 0),
             c(9, 1))
  r10 <- raster |> terra::classify(m, others=NA)
  
  # 2016 only 
  m <- rbind(c(0, 0),
             c(1, 0),
             c(3, 1),
             c(4, 1),
             c(5, 0),
             c(6, 0),
             c(8, 1),
             c(9, 1))
  r16 <- raster |> terra::classify(m,others=NA)
  
  # 2010 and 2016 
  m <- rbind(c(0, 0),
             c(1, 0),
             c(3, 0),
             c(4, 1),
             c(5, 0),
             c(6, 0),
             c(8, 0),
             c(9, 1))
  r1016 <- raster |> terra::classify(m,others=NA)
  return(list(
    r10 = r10,
    r16 = r16,
    r1016 = r1016
  ))
}



## reclass to get a 2016 and 2020 value 
reclassCOT <- function(raster){
  
  
  ## great to translate this to purrr where we have a list of matrix values 

  # 2010 only 
  m <- rbind(c(0, 0),
             c(1, 1),
             c(3, 0),
             c(4, 1),
             c(5, 0),
             c(6, 1),
             c(8, 0),
             c(9, 1))
  r10 <- raster |> terra::classify(m, others=NA)
  
  
  # 2010 and 2016 
  m <- rbind(c(0, 0),
             c(1, 0),
             c(3, 0),
             c(4, 1),
             c(5, 0),
             c(6, 0),
             c(8, 0),
             c(9, 1))
  r1016 <- raster |> terra::classify(m,others=NA)
  
  
  # 2016 only 
  m <- rbind(c(0, 0),
             c(1, 0),
             c(3, 1),
             c(4, 1),
             c(5, 0),
             c(6, 0),
             c(8, 1),
             c(9, 1))
  r16 <- raster |> terra::classify(m,others=NA)
  
  
  # 2016 and 2020 
  m <- rbind(c(0, 0),
             c(1, 0),
             c(3, 0),
             c(4, 0),
             c(5, 0),
             c(6, 0),
             c(8, 1),
             c(9, 1))
  r1620 <- raster |> terra::classify(m,others=NA)
  
  
  
  
  # 2020 only
  m <- rbind(c(0, 0),
             c(1, 0),
             c(3, 0),
             c(4, 0),
             c(5, 1),
             c(6, 1),
             c(8, 1),
             c(9, 1))
  r20 <- raster |> terra::classify(m,others=NA)
  
  return(list(
    r10 = r10,
    r16 = r16, 
    r20 = r20,
    r1016 = r1016,
    r1620 = r1620 
  ))
}






# calArea -----------------------------------------------------------------

calArea <- function(df, type, stableRast, changeRast){
  # grab the positional index 
  index <- grep(pattern = type, x = df$type)
  # calculate counts
  ## stable 
  s1 <- freq(stableRast)
  if(1 %in% s1$value){
    df[index,"stable"] <- s1$count[s1$value == 1]/10000
  }else{
    df[index,"stable"] <- 0 
  }

  ## change 
  c1 <- freq(changeRast)
  # conditional to capture when change is not present 
  if(1 %in% c1$value){
    df[index,"gains"] <- c1$count[c1$value == 1]/10000
  }else{
    df[index,"gains"] <- 0 
  }
  # loss (present in 2010 but not 2016)
  if(-1 %in% c1$value){
    df[index,"loss"] <- c1$count[c1$value == -1]/10000
  }else{
    df[index,"loss"] <- 0 
  }
  #export data 
  return(df)
}


#   processCropLayer ------------------------------------------------------
# testing 
# grid <- g1
# dstable 
# crops <- crops
# year <- "2016"
processCropLayer <- function(grid, crops, stable, change, year, riparian){
  # read and crop crop layer 
  crop1 <- terra::vect(crops[grepl(pattern = paste0(year,".gpkg"), x = crops)])|>
    terra::mask(mask = grid )
  # use as a mask for the stable and change files 
  stableCrop <- terra::mask(x = stable, mask = riparian, inverse = TRUE)|>
    terra::mask(mask = crop1)
  # change raster 
  changeCrop <- terra::mask(x = change, mask = riparian, inverse = TRUE) |> 
    terra::mask(mask = crop1)
  return(list(
    stable = stableCrop,
    change = changeCrop))
}




# calGrass ----------------------------------------------------------------
calGrass <- function(df){
  df[4, "stable"] <- df$stable[1] - sum(df$stable[2:3])
  df[4, "gains"] <- df$gains[1] - sum(df$gains[2:3])
  df[4, "loss"] <- df$loss[1] - sum(df$loss[2:3])
  
  return(df)
}



