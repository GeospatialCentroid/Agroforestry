# load libraries 
pacman::p_load(sf,dplyr,VSURF)
# source functions 
source("agroforestry/0b_vsurf.R")
source("agroforestry/0c_gettingNeighborGrids.R")

# grab the specific grid names 
grids <- sf::st_read("data/processed/griddedFeatures/twelve_mi_grid_uid.gpkg")

# grab some processed data 
files <- list.files(path = "data/processed",
                    pattern = ".geojson",
                    recursive = TRUE,
                    full.names = TRUE)
# define grid ID 
## this is the primary path related structure so it's im
gridIDs <- unique(grids$Unique_ID)

years <- c(2010,2016,2020)

# errors 
errors <- c("X12-289","X12-440","X12-696","X12-727")
gridIDs <- gridIDs[!gridIDs %in% errors]
# 289, 440 - no 2010 data 
# 696 - only 2010
# 727 - 2010 and 2020
# define data path 
dataPath <- "data"
# testing specific site
gridID <- "X12-727"
# for each grid generate variable selection when possible 
for(gridID in gridIDs){
  print(gridID)
  exportPath <- paste0(dataPath, "/processed/", gridID)
  # test to see if data is present 
  if(dir.exists(exportPath)){
    # itorate over the years 
    files <- list.files(exportPath, pattern = ".geojson")
    if(length(files) > 0){
      for(year in years){
        print(year)
        p1 <- files[grepl(pattern = year, x = files)]
        file <- paste0(exportPath, "/", p1)
        # test if input data is present 
        if(file.exists(file)){
          print(file)
          # test if output data already exists 
          output <- paste0(exportPath, "/variableSelection",year,".csv")
          if(!file.exists(output)){
            # read in the file and ensure the 0 1 values are present within the presence column.
            # read in feature
            data <- file |>
              st_read() |> 
              dplyr::mutate(presence = case_when(
                presence == 1 ~ 1,
                TRUE ~ 0
              ))
            data$random <- runif(nrow(data))
            
            sf::write_sf(data, file, delete_dsn =TRUE)
            
            
            # run the variable selection 
            try(rankPredictors <-  variableSelection(gridID = gridID,dataPath = dataPath, year = year))
            #export to a file location  
            try(write.csv(x = rankPredictors, file = output))
            rm(rankPredictors)
          }
        }
      }
    }
    # generate the grid
    nGrid <- defineNeighborGrid(gridID = gridID, dataPath = dataPath)
    write.csv(x = nGrid, file = paste0(exportPath, "/neighborGrids.csv"))
  }
}
