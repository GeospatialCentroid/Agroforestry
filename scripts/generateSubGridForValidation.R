pacman::p_load(sf,dplyr,terra,tmap)
tmap_mode("view")


# model grids -- these are the real sub grid areas for a specific model 
g2010 <- st_read("data/products/modelGrids_2010.gpkg")
g2016 <- st_read("data/products/modelGrids_2016.gpkg")
g2020 <- st_read("data/products/modelGrids_2020.gpkg")
# 2 mile gird 
mile2 <- st_read("data/products/two_sq_grid.gpkg") |>
  dplyr::select(gridID = FID_two_grid)

# gridded features 
# grid12 <- st_read("data/processed/griddedFeatures/twelve_mi_grid_uid.gpkg")
# grid2 <- st_read("data/processed/griddedFeatures/two_sq_grid.gpkg")
# 

# data of 2020 grided features 
df2020 <- data.frame(
  modelGrid = c(    "X12-115","X12-131","X12-150","X12-183","X12-300","X12-307"
    ,"X12-318","X12-32","X12-356","X12-361","X12-388","X12-440","X12-519","X12-602"
    ,"X12-615","X12-624","X12-633","X12-642","X12-677","X12-709","X12-83","X12-91"
    ,"X12-99"),
  subGrid2020 = c("1203","2572","12632","12000","13638","5551","12877","8690","9472",
              "19763","10880","23945","28032","16513","24161","23950","27938",
              "23457","25518","23306","5238","1325","7729") #"7780","8384"
)
df2020$match2010 <- NA
df2020$match2016 <- NA
# if the unique grid is assigned by the model grid assign true for each year 

for(i in 1:nrow(df2020)){
  m1 <- df2020$modelGrid[i]

  m2 <- g2016[g2016$Unique_ID == m1,]
  m3 <- g2010[g2010$Unique_ID == m1,]
  df2020$match2016[i] <- m2$Unique_ID == m2$modelGrid
  df2020$match2010[i] <- m3$Unique_ID == m3$modelGrid
}

# from here 
## pull in the final compost models 
changeOverTime <- list.files("data/products/changeOverTime", full.names = TRUE, pattern = ".tif")
r1 <- terra::rast(changeOverTime[1])
## reclass to get a 2016 and 2020 value 
get2016 <- function(raster, year){
  if(year == 2010){
    m <- c(0, 1, 0,
           1, 1, 1,
           2, 9, 0)
    
    r2 <- r1 |> 
      

      rclmat <- matrix(m, ncol=3, byrow=TRUE)
      rc1 <- classify(r, rclmat, include.lowest=TRUE)
      

  }
  
}


## if the match is TRUE us the 2020 sub grid value 
## else skip -- will assign this later 
## extract the subgrid and export 


# from GEE 
## export all NAIP subgrid. 






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

# for selected areas 
for(i in 1:nrow(df2020)){
  gridID <- df2020$modelGrid[2]
  gridLower <- tolower(gridID)
  model2010 <-
  model2016
  model2020
  model2010 <- terra::rast("data/products/X12-183/x12_183_2010model.tif")
  
  NAIP2010 <- terra::rast(paste0("data/products/",gridID,"/",gridLower,"_2010NAIP.tif"))
  NAIP2016 
  NAIP2020
  NAIP2010 <- terra::rast("data/products/X12-183/x12_183_2010NAIP.tif")
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


# naip images 
NAIP2010 <- terra::rast("data/products/X12-183/x12_183_2010NAIP.tif")
NAIP2016 <- terra::rast("data/products/X12-183/x12_183_2016NAIP.tif")
NAIP2020 <- terra::rast("data/products/X12-183/x12_183_2020NAIP.tif")

# modeled features 
model2010 <- terra::rast("data/products/X12-183/x12_183_2010model.tif")
model2016 <- terra::rast("data/products/X12-183/x12_183_2016model.tif")
model2020 <- terra::rast("data/products/X12-183/x12_183_2020model.tif")


# with randomly selected grids 
for(i in 1:nrow(df2020)){
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



