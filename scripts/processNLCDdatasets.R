library(terra)

# nebraska shp 
neb <- terra::vect("data/processed/nebraska.gpkg") 

# 2016 tcc 
tcc2016 <- terra::rast("data/raw/NLCD/nlcd_tcc_CONUS_2016_v2021-4/nlcd_tcc_CONUS_2016_v2021-4.tif")

processTCClayers <- function(nebraska, nlcd, year, name){
  # reprojects neb 
  neb2 <- nebraska |> 
    terra::project(nlcd)
  # crop and mask layer 
  print("croping layer")
  cm <- nlcd |> 
    terra::crop(neb2) |> 
    terra::mask(neb2)
  name1 <- paste0("tcc",year,".tif")
  # export 
  terra::writeRaster(x = cm,filename = paste0("data/processed/nlcd/",year,"/",name1))
  
  # reclass
  print("reclassing feature")
  m <- c(0, 10, 0,
         10, 100, 1)
  rclmat <- matrix(m, ncol=3, byrow=TRUE)
  rc1 <- classify(cm, rclmat, include.lowest=TRUE)
  # export 
  name2  <- paste0("tcc",year,"_binary.tif")
  terra::writeRaster(x =rc1,filename = paste0("data/processed/nlcd/",year,"/",name2))
  # vectorize 
  print("making polygon")
  # convert to a polygon feature
  p1 <- terra::as.polygons(x = rc1)
  # export 
  name3 <- paste0("tcc",year,"poly.gpkg")
  terra::writeVector(x = p1,filename = paste0("data/processed/nlcd/",year,"/",name3))
}
