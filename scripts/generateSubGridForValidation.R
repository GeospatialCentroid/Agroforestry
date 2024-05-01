pacman::p_load(sf,dplyr,terra,tmap)
tmap_mode("view")

# naip images 
NAIP2010 <- terra::rast("data/products/X12-183/x12_183_2010NAIP.tif")
NAIP2016 <- terra::rast("data/products/X12-183/x12_183_2016NAIP.tif")
NAIP2020 <- terra::rast("data/products/X12-183/x12_183_2020NAIP.tif")

# modeled features 
model2010 <- terra::rast("data/products/X12-183/x12_183_2010model.tif")
model2016 <- terra::rast("data/products/X12-183/x12_183_2016model.tif")
model2020 <- terra::rast("data/products/X12-183/x12_183_2020model.tif")

# gridded features 
grid12 <- st_read("data/processed/griddedFeatures/twelve_mi_grid_uid.gpkg")
grid2 <- st_read("data/processed/griddedFeatures/two_sq_grid.gpkg")


# select AOI 
gridAOI <- grid12[grid12$Unique_ID == "X12-183",]
# select all grids within the AOI 
g2 <- st_intersects(gridAOI,grid2, sparse = FALSE) |> t()

# randomly select three grids from the selected feature 
## i don't know why this the intersection in note coming together 
ranSelection <- grid2[g2[,1], ] |> 
  st_crop(gridAOI)|>
  dplyr::select(FID_two_grid)

# randomly select them 
locations <- sample(1:nrow(ranSelection), 3)
subsamples <- ranSelection[locations, ] |> vect()

# crop the models and NAIP imagery to the subsets 
exportCrop <- function(raster, areas, gridID,year, model){
  gridID2 <- areas$FID_two_grid
  
  if(model == TRUE){
    file <- paste0("data/products/",gridID,"/cropped_model_", year,"_", gridID2, ".tif")
  }else{
    file <- paste0("data/products/",gridID,"/cropped_naip_", year,"_", gridID2, ".tif")
  }
  subset <- terra::crop(x = raster,y = areas)
  terra::writeRaster(x = subset, filename = file, overwrite = TRUE)
}

for(i in 1:nrow(subsamples)){
  # models 
  exportCrop(raster = model2010,
             areas = subsamples[i],
             gridID = "X12-183",
             year = "2010",
             model = TRUE)
  exportCrop(raster = model2016,
             areas = subsamples[i],
             gridID = "X12-183",
             year = "2016",
             model = TRUE)
  exportCrop(raster = model2020,
             areas = subsamples[i],
             gridID = "X12-183",
             year = "2020",
             model = TRUE)
  # naip imagery 
  exportCrop(raster = NAIP2010,
             areas = subsamples[i],
             gridID = "X12-183",
             year = "2010",
             model = FALSE)
  exportCrop(raster = NAIP2016,
             areas = subsamples[i],
             gridID = "X12-183",
             year = "2016",
             model = FALSE)
  exportCrop(raster = NAIP2020,
             areas = subsamples[i],
             gridID = "X12-183",
             year = "2020",
             model = FALSE)
  
}



