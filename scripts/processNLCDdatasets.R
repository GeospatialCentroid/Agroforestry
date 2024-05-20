library(terra)
# library(raster)
# nebraska shp 
neb <- terra::vect("data/processed/nebraska.gpkg") 

# 2016 tcc 
tcc2016 <- terra::rast("data/raw/NLCD/nlcd_tcc_CONUS_2016_v2021-4/nlcd_tcc_CONUS_2016_v2021-4.tif")
# 2010 tcc 
tcc2010 <- terra::rast("data/raw/NLCD/nlcd_tcc_CONUS_2011_v2021-4/nlcd_tcc_CONUS_2011_v2021-4.tif")
# 2020 tcc 
tcc2020 <- terra::rast("data/raw/NLCD/nlcd_tcc_CONUS_2020_v2021-4/nlcd_tcc_CONUS_2020_v2021-4.tif")

# 2020 lcc
lcc2020 <- terra::rast("data/raw/NLCD/nlcd_2019_land_cover_l48_20210604/nlcd_2019_land_cover_l48_20210604.img")
# 2016 lcc
lcc2016 <- terra::rast("data/raw/NLCD/nlcd_2016_land_cover_l48_20210604/nlcd_2016_land_cover_l48_20210604.img")
# 2010 lcc
lcc2010 <- terra::rast("data/raw/NLCD/nlcd_2011_land_cover_l48_20210604/nlcd_2011_land_cover_l48_20210604.img")



processTCClayers <- function(nebraska, nlcd, year){
  # reprojects neb 
  neb2 <- nebraska |> 
    terra::project(nlcd)
  # crop and mask layer 
  print("croping layer")
  file1 <- paste0("data/processed/nlcd/",year,"/",name1)
  if(!file.exists(file1)){
    cm <- nlcd |> 
      terra::crop(neb2) |> 
      terra::mask(neb2)
    name1 <- paste0("tcc",year,".tif")
  # export 
        
    terra::writeRaster(x = cm,filename = file1, overwrite = TRUE)
  }
  
  # reclass
  print("reclassing feature")
  name2  <- paste0("tcc",year,"_binary.tif")
  file2 <- paste0("data/processed/nlcd/",year,"/",name2)
  if(!file.exists(file2)){
    m <- c(0, 10, 0,
           10, 100, 1)
    rclmat <- matrix(m, ncol=3, byrow=TRUE)
    rc1 <- terra::classify(cm, rclmat, include.lowest=TRUE)
    # export
    terra::writeRaster(x =rc1,filename = file2, overwrite = TRUE)
  }else{
    rc1 <- terra::rast(file2)
  }
  
  
  # vectorize 
  print("making polygon")

  # export 
  name3 <- paste0("tcc",year,"poly.gpkg")
  file3 <- paste0("data/processed/nlcd/",year,"/",name3)
  if(!file.exists(file3)){
    # having some issues generating this poly so trying a reclass to forces the NA values 
    rc1 <- ifel(rc1 > 0, 1 , NA)
    # convert to a polygon feature
    p1 <- terra::as.polygons(x = rc1,round = TRUE, na.rm = TRUE, values = TRUE)
    terra::writeVector(x = p1,filename = file3,overwrite=TRUE)
  }
}
processForestClass <- function(nebraska, nlcd, year){
  # reprojects neb 
  neb2 <- nebraska |> 
    terra::project(nlcd)
  # crop and mask layer 
  print("croping layer")
  # select layers of interest 
  name1 <- paste0("forest",year,".tif")
  file1 <- paste0("data/processed/nlcd/",year,"/",name1)
  
  if(!file.exists(file1)){
    cm <- nlcd |> 
      terra::crop(neb2) |> 
      terra::mask(neb2)
    # forest classes 
    ## 41,42,43
    cm2 <- clamp(x = cm, lower = 40, upper = 44, values = FALSE)
    # export 
    terra::writeRaster(x = cm2,filename = file1)
  }else{
    cm2 <- terra::rast(file1)
  }
  
  # reclass
  print("reclassing feature")
  name2  <- paste0("forest",year,"_binary.tif")
  file2 <- paste0("data/processed/nlcd/",year,"/",name2)
  if(!file.exists(file2)){
    rc1 <- ifel(cm2 > 40, 1 , NA)
    # export 
    terra::writeRaster(x =rc1,filename = file2)
  }else{
    rc1 <- terra::rast(file2)
  }
  
  # vectorize 
  print("making polygon")
  
  # export 
  name3 <- paste0("forest",year,"poly.gpkg")
  file3 <- paste0("data/processed/nlcd/",year,"/",name3)
  if(!file.exists(file3)){
    # convert to a polygon feature
    p1 <- terra::as.polygons(x = rc1,na.rm = TRUE, values = TRUE)
    terra::writeVector(x = p1,filename = file3)
  }
}

# apply fuctions 

# 2020
## tcc
processTCClayers(nebraska = neb,
                 nlcd = tcc2020,
                 year = "2020")
## forest 
processForestClass(nebraska = neb,
                   nlcd = lcc2020,
                   year = 2020)

# 2016
## tcc
processTCClayers(nebraska = neb,
                 nlcd = tcc2016,
                 year = 2016)
## forest 
processForestClass(nebraska = neb,
                   nlcd = lcc2016,
                   year = 2016)
# 2010
## tcc
processTCClayers(nebraska = neb,
                 nlcd = tcc2010,
                 year = 2010)
## forest 
processForestClass(nebraska = neb,
                   nlcd = lcc2010,
                   year = 2010)

