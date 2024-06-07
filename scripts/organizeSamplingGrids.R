# for a single year 

# use the classification ranking data to group AOI into specific groups 

# Starting with the top rank model 
## Select all neighbor grids 
## assign model Grid ID to neighbor Grid 
## maintain a list of all used grid ID 

## repret this process with next score but exclude any features already capture but score above 

pacman::p_load(dplyr,sf,googlesheets4,googledrive, purrr,leaflet)


# main grid
grid <- sf::st_read("data/processed/griddedFeatures/twelve_mi_grid_uid.gpkg")

# export sampled girds
sampledgridIds <- c("X12-115","X12-131","X12-150","X12-183","X12-207",
                   "X12-278","X12-281","X12-300","X12-307","X12-318",
                   "X12-32","X12-356","X12-361","X12-388","X12-440",
                   "X12-519","X12-594","X12-602","X12-615","X12-624",
                   "X12-633","X12-635","X12-642","X12-661","X12-677",
                   "X12-709","X12-83","X12-91","X12-99")



grid2 <- grid |>
  dplyr::mutate(
    modelGrid = NA,
    score = NA
  )

# google sheets data 
data2016 <- googlesheets4::read_sheet(
  as_id("https://docs.google.com/spreadsheets/d/1nYkAd_OQdJHV7ZXfOghho9lv9TQEOOvQtnA2lFfrX_Q/edit#gid=2128028285"),
  sheet = "Connor Evaluation2016")
# rename for standardization
names(data2016) <- c("Sample Grid IDs","Reviewed 2016","Score 2016 (Dan)",
                     "Score 2016 (Connor)","Difference","score","average",
                     "rerun","rerun complete", "notes" )

data2010 <- googlesheets4::read_sheet(
  as_id("https://docs.google.com/spreadsheets/d/1nYkAd_OQdJHV7ZXfOghho9lv9TQEOOvQtnA2lFfrX_Q/edit#gid=2128028285"),
  sheet = "Connor Evaluation2010")

data2020 <- googlesheets4::read_sheet(
  as_id("https://docs.google.com/spreadsheets/d/1nYkAd_OQdJHV7ZXfOghho9lv9TQEOOvQtnA2lFfrX_Q/edit#gid=2128028285"),
  sheet = "Connor Evaluation2020")

# testing and function 
dataset <- data2016
scoreValue <- 5
griddedFeature <- grid2
compileModelAreas <- function(scoreValue,dataset, griddedFeature) {
  
  # select rank 5 models 
  dataSelect <- dataset |>
    dplyr::filter(score == scoreValue)|>
    dplyr::select(`Sample Grid IDs`) |>
    pull()
  
  for(i in dataSelect){
    gridID <- i 
    print(gridID)
    # path for reading 
    exportPath <- paste0("data/processed/",gridID)
    
    n1 <- read.csv(paste0(exportPath,"/neighborGrids.csv")) |> 
      dplyr::select(Unique_ID) |> 
      pull()
    
    # assign the score and the model gird reference 
    griddedFeature <- griddedFeature |>
      dplyr::mutate( 
        modelGrid = case_when(
          is.na(modelGrid) & Unique_ID %in% n1 ~ gridID,
          TRUE ~ modelGrid),
        score = case_when(
          is.na(score) & Unique_ID %in% n1 ~ scoreValue,
          TRUE ~ score)
      )
  }
  return(griddedFeature)
}

### 2016 
# for the year itorate over all the score values 
g5 <- compileModelAreas(scoreValue = 5,dataset = data2016, griddedFeature = grid2)
g4 <- compileModelAreas(scoreValue = 4,dataset = data2016, griddedFeature = g5)
g3 <- compileModelAreas(scoreValue = 3,dataset = data2016, griddedFeature = g4)
g2 <- compileModelAreas(scoreValue = 2,dataset = data2016, griddedFeature = g3)
g1 <- compileModelAreas(scoreValue = 1,dataset = data2016, griddedFeature = g2)
g0 <- compileModelAreas(scoreValue = 0,dataset = data2016, griddedFeature = g1)

# export the spatial feature 
sf::st_write(g0,"data/products/modelGrids_2016.gpkg")


### 2020 
# for the year itorate over all the score values 
g5 <- compileModelAreas(scoreValue = 5,dataset = data2020, griddedFeature = grid2)
g4 <- compileModelAreas(scoreValue = 4,dataset = data2020, griddedFeature = g5)
g3 <- compileModelAreas(scoreValue = 3,dataset = data2020, griddedFeature = g4)
g2 <- compileModelAreas(scoreValue = 2,dataset = data2020, griddedFeature = g3)
g1 <- compileModelAreas(scoreValue = 1,dataset = data2020, griddedFeature = g2)
g0 <- compileModelAreas(scoreValue = 0,dataset = data2020, griddedFeature = g1)

# export the spatial feature 
sf::st_write(g0,"data/products/modelGrids_2020.gpkg",delete_layer =TRUE)

# 
gridSampled2 <- gridSampled |>
  dplyr::left_join(y = as.data.frame(st_drop_geometry(g0)), by = c("Unique_ID" = "modelGrid" ))|>
  select(-"Unique_ID.y")|>
  dplyr::distinct()
# join is droppig some data so manueally assign values 
gridSampled2 <- gridSampled2 |>
  dplyr::mutate(score =
    case_when(
      Unique_ID =="X12-278" ~ 1,
      Unique_ID =="X12-281" ~ 1,
      Unique_ID =="X12-594"~ 0,
      Unique_ID =="X12-635" ~ 3,
      Unique_ID =="X12-661" ~ 3,
      TRUE ~ score))

               $
st_write(gridSampled2,"data/products/sampledGrids.gpkg" )



### 2010 
# for the year itorate over all the score values 
g5 <- compileModelAreas(scoreValue = 5,dataset = data2010, griddedFeature = grid2)
g4 <- compileModelAreas(scoreValue = 4,dataset = data2010, griddedFeature = g5)
g3 <- compileModelAreas(scoreValue = 3,dataset = data2010, griddedFeature = g4)
g2 <- compileModelAreas(scoreValue = 2,dataset = data2010, griddedFeature = g3)
g1 <- compileModelAreas(scoreValue = 1,dataset = data2010, griddedFeature = g2)
g0 <- compileModelAreas(scoreValue = 0,dataset = data2010, griddedFeature = g1)

# export the spatial feature 
sf::st_write(g0,"data/products/modelGrids_2010.gpkg")



# might be some clever way to do this with purrr 


