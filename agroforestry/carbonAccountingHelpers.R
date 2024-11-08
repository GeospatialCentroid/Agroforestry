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

