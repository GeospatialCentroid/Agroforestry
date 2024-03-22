library(terra)
library(purrr)
library(tictoc)
gridID <- "X12-356"
shortGridID <- "x356"
dataPath <- paste0("data/products/",gridID)

years <- c(2010,2016,2020)

# list all files 
files <- list.files(path = dataPath,
                    pattern = ".tif",
                    full.names = TRUE,
                    recursive = TRUE)
files2010 <- files[grepl(pattern = paste0(shortGridID,"_2010"), x = files)] 

r1 <- rast(files2010[1])
r2 <- map(.x = files2010, 
          .f = rast)

tic()
r3 <- terra::mosaic(r2[[1]],r2[[3]])
toc()
# r1, r2 422.92 sec elapsed
tic()
r4 <- terra::mosaic(r3,r2[[2]])
toc()

files2016
files2020