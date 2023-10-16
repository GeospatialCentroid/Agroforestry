
#' Generate NDVI values 
#'
#' @param raster terra object with red and ndvi bands present 
#'
#' @return single band raster with NDVI values 
createNDVI <- function(raster){
  r <- raster
  # (NIR - R) / (NIR + R)
  r1 <- (r[[4]] - r[[1]]) / (r[[4]] + r[[1]])
  names(r1) <- paste0(names(r1),"_NDVI")
  return(r1)
}



#' Create GLCM indicies
#'
#' @param band single raster object 
#'
#' @return three raster bands with basic on the input layer
createGLCM <- function(band, name){
  # run the glcm function
  ## currently the window and the statistics are hard coded. Need to be selective
  ## about this so might want to move to the parameters
  vals <- glcm(band,
               window = c(3, 3),
               statistics = 
                 c("entropy", 
                   "second_moment",
                   "correlation")
  )
  # rename the values as these will be part of the stack of multiple indicies
  names(vals) <- paste0(name,"_", names(vals))
  
  return(vals)
}
