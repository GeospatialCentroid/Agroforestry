###
# off off script for evaluating the top predictors of the models 
# 20240327
# carverd@colostate.edu
###


pacman::p_load(googlesheets4, dplyr, readr)



# read in data from drive 
data <- googlesheets4::read_sheet(
  as_id("https://docs.google.com/spreadsheets/d/1nYkAd_OQdJHV7ZXfOghho9lv9TQEOOvQtnA2lFfrX_Q/edit?usp=sharing"),
  sheet = "Evaluation")

# select the models by rank  
selectModels <- function(data, values){
  data |>
    dplyr::filter(`Score 2016` %in% values) |>
    dplyr::select(`Sample Grid IDs`)|>
    pull()
}
goodModels <- selectModels(data, values = c(4,5))
okModels <- selectModels(data, values = c(3))
badModels <- selectModels(data, values = c(1,2))

# use the ids to gather the 
gatherData <- function(id){
  # construct path 
  path <- paste0("data/processed/", id ,"/variableSelection2016.csv")
  # read in data 
  values <- readr::read_csv(path) 
  names(values) <- c("rank", "varNames", "importance", "includedInFinal")
    
  return(values)
}

d1 <- purrr::map(goodModels, gatherData)

               