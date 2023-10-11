raster <- n1
scaleFactors <- c(2,3,4)
#' Upscale rasters 
#'
#' @param raster 
#' @param scaleFactors 
#'
#' @return a list of rasters at values scaled levels
aggregateRasters <- function(raster, scaleFactors){
  # helper function to help order the inputs to the map call
  ag <- function(scaleFactor, raster){
    v1 <- terra::aggregate(x = raster,fact = scaleFactor, fun = "mean")
    names(v1) <- paste0(raster, "_", scaleFactor)
  }
  
  m1 <- purrr::map(.x = scaleFactors,.f = ag, raster = raster)
  
}


