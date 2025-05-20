pacman::p_load(dplyr, stringr, terra)



files <- list.files(
  path = "data/raw/cleanUpModels/imageCleanup",
  full.names = TRUE
)
# move all files into the full image folder for the correct year 
r1 <- rast(files[1])

for(i in files){
  r1 <- terra::rast(i)
  # pull apart basename 
  f1 <- basename(i)
  # split 
  s1 <- stringr::str_split(f1, "_") |> unlist()
  year <- s1[2]
  grid <- s1[1]
  # construct ath 
  path <- paste0("data/products/models",year,"/fullImages/",grid,"_fullUnMasked.tif")
  # export 
  if(!file.exist(path)){
    terra::writeRaster(r1, path, overwrite = TRUE)  
  }
}
