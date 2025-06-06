###
# off off script for evaluating the top predictors of the models 
# 20240327
# carverd@colostate.edu
###


pacman::p_load(googlesheets4, dplyr, readr,googledrive, plotly)



# read in data from drive 
data2016 <- googlesheets4::read_sheet(
  as_id("https://docs.google.com/spreadsheets/d/1nYkAd_OQdJHV7ZXfOghho9lv9TQEOOvQtnA2lFfrX_Q/edit#gid=2128028285"),
  sheet = "Connor Evaluation2016")
names(data2016)[1] <- "Sample Grid IDs"

# select the models by rank  
selectModels <- function(data, values){
  data |>
    dplyr::filter(`average` %in% values) |>
    dplyr::select(`Sample Grid IDs`)|>
    pull()
}

fiveModels <- data2016 |>
  dplyr::filter(`Score 2016 (Dan)` == 5) |>
  dplyr::select(`Sample Grid IDs`)|>
  pull()
goodModels <- selectModels(data = data2016, values = c(4,4.5,5))
okModels <- selectModels(data = data2016, values = c(3,3.5))
badModels <- selectModels(data = data2016, values = c(1,1.5,2,2.5))
oneModels <- data2016 |>
  dplyr::filter(`Score 2016 (Dan)` == 1) |>
  dplyr::select(`Sample Grid IDs`)|>
  pull()


gL <- length(goodModels)
oL <- length(okModels)
bL <- length(badModels)

# use the ids to gather the 
gatherData <- function(id){
  # construct path 
  path <- paste0("data/processed/", id ,"/variableSelection2016.csv")
  if(file.exists(path)){
    # read in data 
    values <- readr::read_csv(path) 
    names(values) <- c("rank", "varNames", "importance", "includedInFinal")
    
    return(values)
  }

}


# Count occurrences of each indicator in each rank group
summarizeData <- function(data, modelClass){
  result <- data |>
    dplyr::group_by(rank, varNames) |>
    dplyr::summarize(count = n())|>
    dplyr::mutate(modelClass = modelClass)
}


# summary the data
fiveData <- purrr::map(fiveModels, gatherData) |>
  dplyr::bind_rows()|>
  # dplyr::filter(includedInFinal == FALSE)|>
  summarizeData(modelClass = "5")
goodData <- purrr::map(goodModels, gatherData) |>
  dplyr::bind_rows()|>
  # dplyr::filter(includedInFinal == FALSE)|>
  summarizeData(modelClass = "4")

okData <- purrr::map(okModels, gatherData) |>
  dplyr::bind_rows()|>
  dplyr::filter(includedInFinal == TRUE)|>
  summarizeData(modelClass = "3")

badData <- purrr::map(badModels, gatherData) |>
  dplyr::bind_rows()|>
  dplyr::filter(includedInFinal == TRUE)|>
  summarizeData(modelClass = "1-2")

allEvals <- dplyr::bind_rows(goodData, okData, badData)

nrow(goodData)/ gL
nrow(okData) / oL
nrow(badData) / bL

# generate plots 
makePlots <- function(data,color){
  plot_ly(data = data, 
          type = "scatter",
          x = ~varNames,
          y = ~rank,
          name = ~modelClass,
          color = ~modelClass,
          colors = c(color))
}

# look at all the plots  --------------------------------------------------
p1 <- makePlots(data = goodData,  color = "#7fff20")
p2 <- makePlots(data = okData,color = "#20efff")
p3 <- makePlots(data = badData,color = "#ffa020")

allPlots <- plotly::subplot(p1,p2,p3,nrows = 3,shareX = TRUE)
allPlots


# look at the best and the worst 
bestWorst <- dplyr::bind_rows(fiveData, oneData)
write_csv(bestWorst, file = "data/processed/evaluation/bestWorstModels2016.csv")
p4 <- makePlots(data = fiveData,  color = "#7fff20")
p5 <- makePlots(data = oneData,color = "#ffa020")

allPlots2 <- plotly::subplot(p4,p5,nrows = 2,shareX = TRUE)
allPlots2
