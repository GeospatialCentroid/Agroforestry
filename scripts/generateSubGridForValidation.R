pacman::p_load(sf,dplyr,terra,tmap)
tmap_mode("view")


# this works... just can't get naip imagery with this method  -------------
## change over time files 
files <-  list.files(path = "data/products/changeOverTime",
                           full.names = TRUE,
                           pattern = ".tif")



# model grids -- these are the real sub grid areas for a specific model 
g2010 <- st_read("data/products/modelGrids_2010.gpkg")
g2016 <- st_read("data/products/modelGrids_2016.gpkg")
g2020 <- st_read("data/products/modelGrids_2020.gpkg")
# 2 mile gird 
mile2 <- st_read("data/products/two_sq_grid.gpkg") |>
  dplyr::select(gridID = FID_two_grid)

qtm(mile2[mile2$gridID == "25518",])
qtm(g2010[g2010$Unique_ID == "X12-636",])


# randomly select new grids  ----------------------------------------------
resample2020 <- c("X12-183","X12-32","X12-388","X12-519","X12-642","X12-677","X12-83","X12-99")
resample2016 <- c("X12-356")
resample2010 <- c("X12-131","X12-32","X12-440","X12-615","X12-624")

# subgrid selection 
subGrid2020 <- c("14308")
subGrid2016 <- c("14308")

randomlySelectSubgrid <-function(gridID, gridSpatailLayer, subGridLayer){
  set.seed(1234) # this doesn't seem to do anything... 
  #select sub grid
  g1 <- gridSpatailLayer |> dplyr::filter(Unique_ID == gridID)
  # crop the two mile
  s1 <- sf::st_crop(x = subGridLayer, y = g1)
  # random position 
  random <- sample(1:nrow(s1), 1)
  # pull sub grid ID 
  subGridID <- s1$gridID[random]
  print(paste0(gridID," : ", subGridID ))
  return(subGridID)
}

# single call 
randomlySelectSubgrid(gridID =resample2016,
                      gridSpatailLayer =g2016,
                      subGridLayer= mile2 )


# pull sub grids
sub2020 <- purrr::map(.x = resample2020, .f = randomlySelectSubgrid,  
                      gridSpatailLayer = g2020, subGridLayer = mile2) |> unlist()
sub2016 <- purrr::map(.x = resample2016, .f = randomlySelectSubgrid,  
                     gridSpatailLayer = g2016, subGridLayer = mile2)|> unlist()
sub2010 <- purrr::map(.x = resample2010, .f = randomlySelectSubgrid,  
                      gridSpatailLayer = g2010, subGridLayer = mile2)|> unlist()

produceSubGrids <- function(data, subGridLayer, modelGrid, changeOverTime, year){
  # get the sub grid name
  subGridID <- data
  print(subGridID)
  # select the spatial object 
  subGrid <- subGridLayer[subGridLayer$gridID == subGridID, ]
  # get model grid id 
  uniqueGrid <- modelGrid$Unique_ID[sf::st_intersects(modelGrid, y = subGrid, sparse = FALSE)]
  if(length(uniqueGrid)==1){
    # select the raster if interest 
    r1 <- terra::rast(changeOverTime[grepl(pattern = paste0(uniqueGrid,"_"), x = changeOverTime)])
    # export 
    fileName <- paste0("data/products/subGridAreaEvaluations/subGrid_", uniqueGrid, "_",subGridID,"_",year,".tif")
    if(!file.exists(fileName)){
      r2 <- "test"
      try(
        r2 <- getYearMap(raster = r1, year = year) |>
        terra::crop(subGrid)
        )
      if(class(r2)!="character"){
        terra::writeRaster(x = r2, 
                           filename = fileName,
                           overwrite = TRUE)
      }
    }
  }else{
    for(i in uniqueGrid){
      # select the raster if interest 
      r1 <- terra::rast(changeOverTime[grepl(pattern = paste0(i,"_"), x = changeOverTime)])
      # export 
      fileName <- paste0("data/products/subGridAreaEvaluations/subGrid_", i, "_",subGridID,"_",year,".tif")
      if(!file.exists(fileName)){
        r2 <- "test"
        try(r2 <- getYearMap(raster = r1, year = year) |>
              terra::crop(subGrid))
        if(class(r2)!="character"){
          terra::writeRaster(x = r2, 
                             filename = fileName,
                              overwrite = TRUE)
        }
      }
    }
  }
}
## single call 
produceSubGrids(data = "26457", 
                subGridLayer = mile2,
                modelGrid = g2016,
                changeOverTime = files,
                year = "2010")

getYearMap <- function(raster, year){
  if(year == 2010){
    # define the replacement values 
    m <- rbind(c(0, 0),
               c(1, 1),
               c(3, 0),
               c(4, 0),
               c(5, 0),
               c(6, 0),
               c(8, 0),
               c(9, 0))
    r2 <- raster$ChangeOverTime |> 
      terra::classify(m,others=NA)
  }
  if(year == 2016){
    # define the replacement values 
    m <- rbind(c(0, 0),
               c(1, 0),
               c(3, 1),
               c(4, 0),
               c(5, 0),
               c(6, 0),
               c(8, 0),
               c(9, 0))
    r2 <- r1$ChangeOverTime |> 
      terra::classify(m,others=NA)
  }
  if(year == 2020){
    # define the replacement values 
    m <- rbind(c(0, 0),
               c(1, 0),
               c(3, 0),
               c(4, 0),
               c(5, 1),
               c(6, 0),
               c(8, 0),
               c(9, 0))
    r2 <- r1$ChangeOverTime |> 
      terra::classify(m,others=NA)
  }
  return(r2)
}
# 2020
purrr::map(.x = sub2020, .f = produceSubGrids, 
           subGridLayer = mile2,
           modelGrid = g2020,
           changeOverTime = files,
           year = "2020")
# 2016
purrr::map(.x = sub2016, .f = produceSubGrids, 
           subGridLayer = mile2,
           modelGrid = g2016,
           changeOverTime = changeOverTime,
           year = "2016")
#2010 
purrr::map(.x = sub2010, .f = produceSubGrids, 
           subGridLayer = mile2,
           modelGrid = g2010,
           changeOverTime = changeOverTime,
           year = "2010")








# gridded features 
# grid12 <- st_read("data/processed/griddedFeatures/twelve_mi_grid_uid.gpkg")
# grid2 <- st_read("data/processed/griddedFeatures/two_sq_grid.gpkg")
# 

# data of 2020 grided features 
df2020 <- data.frame(
  modelGrid = c(    "X12-131","X12-356","X12-602","X12-615"),
  subGrid2020 = c("6188","14308", "24675","26298") #"7780","8384"
)
# add columns for the cause in which there is no 2020 match 
df2016 <- data.frame(
  modelGrid = c("X12-115","X12-131","X12-150","X12-183","X12-278",
                "X12-300","X12-307","X12-318","X12-356","X12-361","X12-388",
                "X12-519","X12-594","X12-602","X12-624","X12-642","X12-661","X12-677",
                "X12-709","X12-83","X12-91","X12-99"),
  subGrid2016 = c("594","456","12659","11710","18037","5822","6165","8345","12781",
                  "11319","22986","24110","17395","20451","30590","27975","30823","24297","30850","2828","1328",
                  "4121") 
)

df2010 <- data.frame(
  modelGrid = c("X12-115","X12-131","X12-150","X12-183","X12-207","X12-278","X12-281","X12-300","X12-307",
                "X12-318","X12-32","X12-356","X12-361","X12-388","X12-440","X12-519","X12-594","X12-602",
                "X12-615","X12-624","X12-642","X12-677","X12-83","X12-91","X12-99"),
  subGrid2010 = c("1200","1661","12963","9286","4330","19547","14758","15787","11577","8341","1473","22744",
                  "18876","17530","23005","28330","27935","22584","27785","29389","27083","30605","402",
                  "2233","4428") 
)

#combined datasets
df2020 <- df2020|>
  dplyr::full_join(df2016,by = "modelGrid")|>
  dplyr::full_join(df2010,by = "modelGrid")

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


# no models in 2020
df2020a <- df2020[!is.na(df2020$subGrid2020),]
# this is going to require a bit more specific of a workflow so just pulling out for now. 
df2020b <- df2020[is.na(df2020$subGrid2020),]


# match on all three years 
dfall <- df2020a |>
  dplyr::filter(match2010 == TRUE & match2016 == TRUE)
  
# from here 
## pull in the final compost models 
changeOverTime <- list.files("data/products/changeOverTime", full.names = TRUE, pattern = ".tif")


r1 <- terra::rast(changeOverTime[1])
## reclass to get a 2016 and 2020 value 
getYearMap <- function(raster, year){
  if(year == 2010){
    # define the replacement values 
    m <- rbind(c(0, 0),
               c(1, 1),
               c(3, 0),
               c(4, 0),
               c(5, 0),
               c(6, 0),
               c(8, 0),
               c(9, 0))
    r2 <- r1$ChangeOverTime |> 
      terra::classify(m,others=NA)
  }
  if(year == 2016){
    # define the replacement values 
    m <- rbind(c(0, 0),
               c(1, 0),
               c(3, 1),
               c(4, 0),
               c(5, 0),
               c(6, 0),
               c(8, 0),
               c(9, 0))
    r2 <- r1$ChangeOverTime |> 
      terra::classify(m,others=NA)
  }
  if(year == 2020){
    # define the replacement values 
    m <- rbind(c(0, 0),
               c(1, 0),
               c(3, 0),
               c(4, 0),
               c(5, 1),
               c(6, 0),
               c(8, 0),
               c(9, 0))
    r2 <- r1$ChangeOverTime |> 
      terra::classify(m,others=NA)
  }
  return(r2)
}

index <- 1:nrow(df2020)
produceSubGrids <- function(index, data, subGridLayer, modelGrid, changeOverTime, year){
  df <- data[index, ]
  subGrid <- subGridLayer[subGridLayer$gridID == df[,2], ]
  
  uniqueGrid <- modelGrid$Unique_ID[sf::st_intersects(modelGrid, y = subGrid, sparse = FALSE)]
  r1 <- terra::rast(changeOverTime[grepl(pattern = paste0(uniqueGrid,"_"), x = changeOverTime)])
  
  try(r2 <- getYearMap(raster = r1, year = year)|>
        terra::crop(subGrid),
      terra::writeRaster(x = r2, 
                         filename = paste0("data/products/subGridAreaEvaluations/subGrid_", uniqueGrid, "_",subGrid,"_",year,".tif")))
}



# original ----------------------------------------------------------------
for(i in 1:nrow(df2020a)){
  # select specific row   
  df <- df2020a[i,]
  # extract the subgrid  
  subGrid <- mile2[mile2$gridID == df$subGrid2020, ]
  # the model grid is not the same of the grid that was applied. Use an intersection to select the specific area. 
  uniqueGrid <- g2020$Unique_ID[sf::st_intersects(g2020, y = subGrid, sparse = FALSE)]
  # read in object from list of change over time rasters 
  r1 <- terra::rast(changeOverTime[grepl(pattern = paste0(uniqueGrid,"_"), x = changeOverTime)])
  #2010
  if(df$match2010 == TRUE){
    try(r2010 <- getYearMap(raster = r1, year = 2010)|>
      terra::crop(subGrid),
    terra::writeRaster(x = r2010, 
                       filename = paste0("data/products/subGridAreaEvaluations/subGrid_", df$modelGrid, "_",df$subGrid2020,"_2010.tif")))
  }else{
    # if(!is.na(df$subGrid2010)){
    #   subGridb <- mile2[mile2$gridID == df$subGrid2010, ]
    #   uniqueGridb <- g2010$Unique_ID[sf::st_intersects(g2010, y = subGridb, sparse = FALSE)][2]
    #   r1b <- terra::rast(changeOverTime[grepl(pattern = paste0(uniqueGridb,"_"), x = changeOverTime)])
    #   r2010 <- getYearMap(raster = r1b, year = 2010)|>
    #     terra::crop(subGridb)
    #   terra::writeRaster(x = r2010, 
    #                      filename = paste0("data/products/subGridAreaEvaluations/subGrid_", df$modelGrid, "_",subGridb,"_2010.tif"))
    # }
  }
  #2016
  if(df$match2016 == TRUE){
    try(r2016 <- getYearMap(raster = r1, year = 2016)|>
      terra::crop(subGrid),
    terra::writeRaster(x = r2016, 
                       filename = paste0("data/products/subGridAreaEvaluations/subGrid_", df$modelGrid, "_",df$subGrid2020,"_2016.tif")))
  }else{
    # if(!is.na(df$subGrid2016)){
    #   subGridb <- mile2[mile2$gridID == df$subGrid2016, ]
    #   uniqueGridb <- g2016$Unique_ID[sf::st_intersects(g2016, y = subGridb, sparse = FALSE)]
    #   r1b <- terra::rast(changeOverTime[grepl(pattern = paste0(uniqueGridb,"_"), x = changeOverTime)])
    #   r2016 <- getYearMap(raster = r1b, year = 2016)|>
    #     terra::crop(subGridb)
    #   terra::writeRaster(x = r2016, 
    #                      filename = paste0("data/products/subGridAreaEvaluations/subGrid_", df$modelGrid, "_",subGridb,"_2016.tif"))
    # }
  }
  #2020
  try(r2020 <- getYearMap(raster = r1, year = 2020)|>
    terra::crop(subGrid),
  terra::writeRaster(x = r2020, 
                     filename = paste0("data/products/subGridAreaEvaluations/subGrid_", df$modelGrid, "_",df$subGrid2020,"_2020.tif")))
}
## if the match is TRUE us the 2020 sub grid value 
## else skip -- will assign this later 







#2020
r2020 <- getYearMap(raster = r1, year = 2020)|>
  terra::crop(subGrid)
terra::writeRaster(x = r2020, 
                     filename = paste0("data/products/subGridAreaEvaluations/subGrid_", df$modelGrid, "_",df$subGrid2020,"_2020.tif"))


# from GEE 
## export all NAIP subgrid. 



tmap::tm_polygons()


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



