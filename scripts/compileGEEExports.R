library(terra)
library(purrr)

gridID <- "X12-150"
shortGridID <- "x150"
dataPath <- paste0("data/products/",gridID)

years <- c(2010,2016,2020)

# list all files 
files <- list.files(path = dataPath,
                    pattern = ".tif",
                    full.names = TRUE,
                    recursive = TRUE)
files2010 <- files[grepl(pattern = paste0(shortGridID,"2010"), x = files)] 
r1 <- rast(files2010[1])
r2 <- map(.x = files2010, 
          .f = rast)

r3 <- terra::mosaic(r2[[1]],r2[[3]])

files2016
files2020