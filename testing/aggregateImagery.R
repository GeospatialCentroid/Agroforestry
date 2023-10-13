#' 
#' #' convert aggregate to map friendly structure
#' #'
#' #' @param scaleFactor 
#' #' @param raster 
#' #'
#' #' @return
ag <- function(scaleFactor, raster){
  v1 <- terra::aggregate(x = raster,fact = scaleFactor, fun = "mean")
  names(v1) <- paste0(names(raster), "_", scaleFactor)
  return(v1)
}






# raster <- n1
# scaleFactors <- c(2,3,4)
#' Upscale rasters 
#'
#' @param raster 
#' @param scaleFactors 
#'
#' @return a list of rasters at values scaled levels
aggregateRasters <- function(raster, scaleFactors, parallel, ag = ag){

  
  # helper function to help order the inputs to the map call
  if(parallel == TRUE){
    m1 <- furrr::future_map(.x = scaleFactors, 
                            .f = ag,
                            raster =raster)
  }else{
    m1 <- purrr::map(.x = scaleFactors,
                     .f = ag,
                     raster = raster)
  }
  # conver m1 to a vector of raster objects 
  rasters <- c()
  for(i in 1:length(m1)){
    rasters[i] <-m1[[i]]
  }
  return(m1)
}


