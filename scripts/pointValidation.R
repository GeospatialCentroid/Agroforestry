###

pacman::p_load("sf", "dplyr", "purrr", "tmap",stringr)
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




extractVals <- function(grid, year, valData1){

  # image paths 
  pathToImages <- paste0("data/products/models",year,"/fullImages")
  images <- list.files(
    path = pathToImages,
    pattern = ".tif",
    full.names = TRUE
  )
  img <- images[grepl(pattern = paste0(grid,"_full"), x = images)] |>
      terra::rast()
  v2 <- valData1[valData1$gridID == grid, ]
    
    
    # extract values 
    v3 <- terra::extract(x = img,
                         y = v2,
                         bind = TRUE) |>
      as.data.frame()
    names(v3) <- c("gridID","presence","year","predictedValue")
    
  return(v3)
}

## issues with x12_310 so I'm droping here
# set yread value 
year <- 2010
# select value data based on year
valData1 <- valData[grepl(pattern = year, x = valData)] |> terra::vect()
# select the grid 
grids <- unique(valData1$gridID)
grids <- grids[!grids %in% c("X12_310","X12_588", "X12_727") ]
referenceData <- grids |>
  purrr::map(.f = extractVals,
             year = 2016, 
             valData1 = valData1) |>
  bind_rows()
for(i in years){
  year <- i
  # select value data based on year
  valData1 <- valData[grepl(pattern = year, x = valData)] |> terra::vect()
  # select the grid 
  grids <- unique(valData1$gridID)
  # some year specific indexing maybe
  grids <- grids[!grids %in% c("X12_310","X12_588", "X12_727") ]
  # run test
  referenceData <- grids |>
    purrr::map(.f = extractVals,
               year = year, 
               valData1 = valData1) |>
    bind_rows()
  write.csv(x = referenceData,
            file = paste0("data/processed/validationPoints/referenceValidation_",year,".csv")
            )  
}


# visualize the results  --------------------------------------------------
library(caret)
files <- list.files(path = "data/processed/validationPoints",
                    pattern = ".csv",
                    full.names = TRUE)
r1 <- read.csv(files[1])

r2 <- r1[r1$gridID == "X12-115", ]
m1 <- caret::confusionMatrix(data = factor(r2$presence, levels = c(1,0)), reference = factor(r2$predictedValue,levels = c(1,0)))
m1
# m1
class(m1)
m1$positive
m1$table
m1$overall
m1$byClass

ids <- unique(r1$gridID)


d1 <- data.frame(gridID = ids, year = 2010, totalPresence = NA, totalAbsense = NA,Accuracy = NA,Kappa = NA, Sensitivity= NA, Specificity =NA)

for(i in seq_along(ids)){
  r2 <- r1[r1$gridID == ids[i],]
  m1 <-  caret::confusionMatrix(data = factor(r2$presence, levels = c(1,0)), reference = factor(r2$predictedValue,levels = c(1,0)))
  d1[i, 3:4] <- m1$overall[1:2]
  d1[i, 5:6] <- m1$byClass[1:2] 
}


generateEvaluationStats <- function(year, files){
  file <- files[grepl(pattern = year, x = files)]
  # read in data
  d1 <- read.csv(file)
  ids <- unique(d1$gridID)
  # generate a storage datframe 
  d2 <- data.frame(year = year,
                   gridID = ids,
                   totalPresence = NA, 
                   totalAbsense = NA,
                   modelPresence = NA,
                   modelAbsense = NA, 
                   Accuracy = NA,
                   Kappa = NA,
                   Sensitivity= NA,
                   Specificity =NA)
  for(i in seq_along(ids)){
    r2 <- d1[d1$gridID == ids[i],]
    m1 <-  caret::confusionMatrix(data = factor(r2$presence, levels = c(1,0)), reference = factor(r2$predictedValue,levels = c(1,0)))
    d2[i, "totalPresence"] <- nrow(r2[r2$presence==1,])
    d2[i, "totalAbsense"] <- nrow(r2[r2$presence==0,])
    d2[i, "modelPresence"] <- nrow(r2[r2$predictedValue==1,])
    d2[i, "modelAbsense"] <- nrow(r2[r2$predictedValue==0,])
    
    d2[i, 7:8] <- m1$overall[1:2]
    d2[i, 9:10] <- m1$byClass[1:2] 
  }
  return(d2)
}

evaluationsSummary <- years |>
  purrr::map(generateEvaluationStats, files = files)|>
  dplyr::bind_rows()

write.csv(evaluationsSummary,file =  paste0("data/processed/validationPoints/referenceValidation_summaryAllyears.csv") )

