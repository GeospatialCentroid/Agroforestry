
## CSB layers from https://www.nass.usda.gov/Research_and_Science/Crop-Sequence-Boundaries/index.php
## 2010 crop reference - not working... 
## will try a drive download 
# download.file(url = "https://www.nass.usda.gov/Research_and_Science/Crop-Sequence-Boundaries/datasets/NationalCSB_2008-2015_rev23.zip",
#               destfile = "data/csb",cacheOK = TRUE)
# ## 2016 crop reference 
# download.file(url = "https://www.nass.usda.gov/Research_and_Science/Crop-Sequence-Boundaries/datasets/NationalCSB_2012-2019_rev23.zip",
#               destfile = "data/csb")
# ## 2020 crop reference 
# download.file(url = "https://www.nass.usda.gov/Research_and_Science/Crop-Sequence-Boundaries/datasets/NationalCSB_2016-2023_rev23.zip",
#               destfile = "data/csb")


# I'm downloading these locally, loading them to gdrive, then transfering to the server for processing. 

pacman::p_load(googledrive, terra, dplyr,tigris)

#2010 data
## set the working directory for download 

# googledrive::drive_download(file = as_id("https://drive.google.com/file/d/1u3oZkqEVgwMYyFtscpJt6T_8KbjdG60S/view?usp=drive_link"))
path2010 <-"data/raw/csb/NationalCSB_2008-2015_rev23/CSB0815.gdb"
if(!file.exists(path2010)){
  unzip(zipfile = "~/Documents/Agroforestry/data/raw/csb/NationalCSB_2008-2015_rev23.zip")
  
}
#2016 data
# googledrive::drive_download(file = as_id("https://drive.google.com/file/d/1EhFzYlaI5wpuAi6nln5V-hXx7hHN1oqZ/view?usp=sharing"))
path2016 <-"data/raw/csb/NationalCSB_2012-2019_rev23/CSB1219.gdb"
if(!file.exists(path2016)){
  unzip(zipfile = "~/Documents/Agroforestry/data/raw/csb/NationalCSB_2012-2019_rev23.zip")
}


#2020 data
# googledrive::drive_download(file = as_id("https://drive.google.com/file/d/1y1gtJjJp4L7VAIjvZh9lK4v8nDoJsVhG/view?usp=sharing"))
path2020 <-"data/raw/csb/NationalCSB_2016-2023_rev23/CSB1623.gdb"
if(!file.exists(path2020)){
  unzip(zipfile = "~/Documents/Agroforestry/data/raw/csb/NationalCSB_2016-2023_rev23.zip")
}



readAndClip <-function(csb){
  # read in the csb data 
  d1 <- terra::vect(csb)  
  # subset on fips 
  d2 <- terra::subset(d1, d1$STATEFIPS == 31)
  return(d2)
}

#2020 
r20 <- readAndClip(path2020) |> 
  terra::project("epsg:4326")
terra::writeVector(x = r20, filename = "data/processed/csb/nebraskaCSB2020.gpkg", overwrite = TRUE )
#2016

r16 <- readAndClip(path2016) |> 
  terra::project("epsg:4326")
terra::writeVector(x = r16, filename = "data/processed/csb/nebraskaCSB2016.gpkg")
#2010
r10 <- readAndClip(path2010) |> 
  terra::project("epsg:4326")
terra::writeVector(x = r10, filename = "data/processed/csb/nebraskaCSB2010.gpkg")

