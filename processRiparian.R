pacman::p_load(terra, sf, dplyr, googledrive,
               stringr,tmap)

# riparian data download and project --------------------------------------
riparian <- images[images$name == "nebraskaRiparian.tif", ]
googledrive::drive_download(as_id(riparian$id),
                            path = paste0("data/raw/riparian/riparianArea10.tif"))

r10proj <- terra::rast("data/raw/riparian/riparianArea10.tif")|>
  terra::project("+init=EPSG:4326")
terra::writeRaster(r10proj ,
                   filename = "data/products/riparian/nebraskaRiparian10.tif",
                   overwrite = TRUE)
riparianRast30 <- terra::rast("data/raw/riparian/riparianArea30.tif")

r30proj <- riparianRast30 |>
  terra::project("+init=EPSG:4326")
terra::writeRaster(r30proj, filename = "data/products/riparian/nebraskaRiparian30.tif")
