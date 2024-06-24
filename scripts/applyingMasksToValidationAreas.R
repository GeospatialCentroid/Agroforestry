

#### work from centroid computer 


library(terra)
library(dplyr)
library(stringr)

# read in mask layers 
nlcdMasks <- list.files("data/processed/nlcd",pattern = ".gpkg", full.names = TRUE, recursive = TRUE)
# tccs <- nlcdMasks[grepl(pattern = "tcc", nlcdMasks)]
forests <- nlcdMasks[grepl(pattern = "forest", nlcdMasks)]
# urban areas 
urbanFiles <- list.files("data/raw/censusData/", pattern = "*\\.shp", full.names = TRUE, recursive = TRUE )
urbanFiles2 <- urbanFiles[str_ends(string = urbanFiles, pattern = ".shp")]

# set year 
year <- 2016
# grab year of interest
# tccVal <- terra::vect(tccs[grepl(pattern = year, x = tccs)])
forestVal <- terra::vect(forests[grepl(pattern = year, x = forests)])

# grab the validation data
files <- list.files(paste0("data/products/samplingAreas/",year,"/"),full.names = TRUE)
validationFiles <- files[grepl(pattern = "validationGrid", files)]
naipFiles <- files[grepl(pattern = "naipGrid", files)]
naipFiles <- naipFiles[!grepl(pattern = ".xml", naipFiles)]

# NAIP data
for(i in 1:length(naipFiles)){
 # select file
   n1 <- naipFiles[i] 
   print(n1)
# pull name for reference 
   name1 <- stringr::str_remove(basename(n1), pattern = ".tif")
   fileName1 <- paste0("data/products/samplingAreas/",year,"/rendered/",name1,"_reproject.tif")
if(!file.exists(fileName1)){
  # reproject
  n2 <- terra::rast(n1) |>
    terra::project(forestVal)
  # export 
  terra::writeRaster(n2, filename = fileName1,
                     overwrite = TRUE)
  }
}



# forest mask layer and city mask 
for(i in 1:length(validationFiles)){
  r1 <- validationFiles[i]
  print(r1)
  # pull name for reference 
  name1 <- stringr::str_remove(basename(r1), pattern = ".tif")
  fileName2 <- paste0("data/products/samplingAreas/",year,"/rendered/",name1,"_Masked.tif")
  fileName3 <- paste0("data/products/samplingAreas/",year,"/rendered/",name1,"_Mask_Only.tif")
  
  u1 <- urbanFiles2[grepl(pattern = year, urbanFiles2)]
  if(!file.exists(fileName2)){
    # read in forest data and reprojects
  r2 <- terra::rast(r1) |>
    terra::project(forestVal)
    # read in urban data and reproject 
  u2 <- terra::vect(u1) |>
    terra::project(forestVal)|>
    terra::crop(r2)
  if(nrow(u2)!=0){
    print("removing town")
    r2 <- r2 |>
      terra::mask(u2, inverse = TRUE,updatevalue=2)
  }

  # crop tcc 
  forest2 <-  forestVal |>
    terra::crop(r2)
  # mask 
  r3 <- r2 |>
    terra::mask(forest2, inverse = TRUE,updatevalue=2)
  # export mask object
  terra::writeRaster(r3, filename = fileName2,
                     overwrite = TRUE)
  # export 
  r4 <- ifel(r3 <= 1, NA , 1)
  #export the mask layer 
  terra::writeRaster(r4, filename = fileName3,
                     overwrite = TRUE)
  
  }
}

