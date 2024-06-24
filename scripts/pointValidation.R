###

pacman::p_load("sf", "dplyr", "purrr", "tmap")
tmap_mode("view")

# gather all the test train data  -----------------------------------------
files <- list.files(path = 'data/processed',
           pattern = "agroforestrySamplingData",
           full.names = TRUE,
           recursive = TRUE)
t1 <- st_read(files[10])

# function to process data
processPointFiles <- function(year, files){
  f1 <- files[grepl(pattern = paste0("_",year), x = files)] |> 
    purrr::map(.f = st_read) |>
    dplyr::bind_rows()|>
    # dplyr::select(presense, random)|>
    dplyr::filter(random > 0.8) |>
    dplyr::mutate(year= year)
  return(f1)
}
years <-  c("2010","2016","2020")
validataionData <- purrr::map(.x = years,
                              .f = processPointFiles,
                              files = files) |>
  dplyr::bind_rows()|>
  filter(!is.na(presence)) |>
  dplyr::select(year, presence, random)


for(i in years){
  d1 <- validataionData |>
    dplyr::filter(year == i)|>
    sf::st_write(
      dsn = paste0("data/processed/validationPoints/validationSet_",i,".gpkg"),
      delete_dsn = TRUE
    )
}


st_write(obj = validataionData$`2010`,
         "data/processed/validationPoints/filtered2010.gpkg")
st_write(obj = validataionData$`2016`,
         "data/processed/validationPoints/filtered2016.gpkg")
st_write(obj = validataionData$`2020`,
         "data/processed/validationPoints/filtered2020.gpkg")
# export 


### after this I'll want to load in all the unmasked images connected 
### with a specific model grid.
### pull in the model grid object 
### get the max extent of that model grid and use that to clip the points 
### intersect to determine which sub grids have points 
### load in those subgrids and intersect 
