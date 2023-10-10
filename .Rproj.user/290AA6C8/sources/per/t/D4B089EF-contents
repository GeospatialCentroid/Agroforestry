pacman::p_load(terra, raster, glcm, purrr)

path <- "C:/Users/carverd/Desktop/Agroforestry/data/naip/m_4209749_sw_14_h_20160821_20161019.jp2"
fileLocation <- "C:/Users/carverd/Desktop/Agroforestry/data/naip"  

bindNAIP <- function(fileLocation){
  f1 <- list.files(path = fileLocation, pattern = ".jp2", full.names = TRUE)
  r1 <- map(.x = f1, .f = rast)
  for(i in seq_along(r1)){
    if(i == 1){
      r2 <- r1[[i]]
    }else{
      r2 <- terra::merge(r2, r1[[i]])
    }
  }
  r2 <- map(r1, terra::merge)
  
    
}



processCountyNAIP <- (path){
  # read in features 
  t1 <- terra::rast(path)

  # calculate Brightness 
  ## mean of all four bands 
  t2 <- terra::mean(t1)
  
  # generate NDVI 
  ndvi <- (t)
  # generate RBG 
  
  # 1st level texture 
  ## focal window -- 3 by 3 standard devation of 
  
  # texture calculation 
  ## https://cran.r-project.org/web/packages/glcm/glcm.pdf
  t1 <-  glcm::L5TSR_1986
  t2 <- glcm::glcm(x = t1[[1]])
  }