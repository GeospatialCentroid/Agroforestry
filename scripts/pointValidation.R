###

pacman::p_load("sf", "dplyr", "purrr", "tmap")
tmap_mode("view")

# gather all the test train data  -----------------------------------------
files <- list.files(path = 'data/processed',
           pattern = "agroforestrySamplingData",
           full.names = TRUE,
           recursive = TRUE)
t1 <- st_read(files[1])
t2 <- st_read(files[2])
t3 <- st_read(files[100])
# function to process data
processPointFiles <- function(year, files){
  # select all files from the years 
  f1 <- files[grepl(pattern = paste0("_",year), x = files)] 
  # pull out the unique grid id from file names 
  ## function for grabing elements 
  selectGrid <- function(path){
    p1 <- stringr::str_split(string = path,
                             pattern = "/") |>
      unlist()
    p1[3]
  }
  # vector for nameing 
  ids <- lapply(X = f1 , selectGrid) |> unlist()
  
  # assign grid 
  assignGrid <- function(paths, gridID){
    val <- st_read(paths)|>
      dplyr::mutate(gridID = gridID) 
      # # dplyr::select(presense, random)|>
      # dplyr::filter(random > 0.8) |>
      # dplyr::mutate(year= year)
  }
  f2 <- f1 |> 
    purrr::map2(ids, assignGrid)|>
    bind_rows() |>
    filter(!is.na(presence),
           !is.na(gridID),
           gridID != "0",
           gridID != "") |> 
    dplyr::filter(random > 0.8) |>
    dplyr::mutate(year= year) |>
    dplyr::select(gridID,presence, year, geometry)
    
  return(f2)
}

years <-  c("2010","2016","2020")
validatationData <- purrr::map(.x = years,
                              .f = processPointFiles,
                              files = files) |>
  bind_rows()
### 
# so lumping things into years might be aribiraty as there is only 
# one positional dataset. That said, the randon value is unique to the modeling years
# this means that different spilts were used to determine test and train between modeling efforts
###

for(i in years){
  d1 <- validatationData |>
    dplyr::filter(year == i)|>
    sf::st_write(
      dsn = paste0("data/processed/validationPoints/validationSet_",i,".gpkg"),
      delete_dsn = TRUE
    )
}


### after this I'll want to load in all the unmasked images connected 
### with a specific model grid.
### pull in the model grid object 
### get the max extent of that model grid and use that to clip the points 
### intersect to determine which sub grids have points 
### load in those subgrids and intersect 

years <-  c("2010","2016","2020")
valData <- list.files(path = "data/processed/validationPoints",
                      pattern = "validationSet",
                      full.names = TRUE)
#list images within the function 

### with a specific model grid.
v1 <- st_read(valData[1])
grids <- unique(v1$gridID)
pathToImages <- paste0()




