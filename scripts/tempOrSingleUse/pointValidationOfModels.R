pacman::p_load(sf, terra, dplyr,readr)


# generate confusion matrix for the individul models 
confusionMatrix <- function(year){
  # pull in point datasets 
  files <- list.files(paste0("data/processed/validationPoints"),
                      pattern = year,
                      full.names = TRUE)
  data <- files[grepl(pattern = ".csv", files)] |>
    read_csv()
  
  conMatrix <- data |>
    group_by(gridID) |>
    summarise(
      # Count the four outcomes
      TP = sum(presence == 1 & predictedValue == 1),
      FN = sum(presence == 1 & predictedValue == 0),
      TN = sum(presence == 0 & predictedValue == 0),
      FP = sum(presence == 0 & predictedValue == 1),
      # Calculate the rates using the counts
      truePositiveRate = .data$TP / (.data$TP + .data$FN),
      trueNegitiveRate = .data$TN / (.data$TN + .data$FP)
    ) |>
    dplyr::mutate(year = year)
  return(conMatrix)
}

# 
cm1 <- purrr::map(.x = c("2010","2016", "2020"), .f = confusionMatrix) |>
  bind_rows()
# export 
write_csv(x = cm1, file = "data/processed/validationPoints/refValShort_allYears.csv")

# render matrix with all points 
## pull all training data, extract to model and generate new matrix 

year <- "2010"

extractConMax <- function(year){
  grid <- st_read(paste0("data/products/modelGrids_",year,".gpkg")) 
  
  uniqueModels <- unique(grid$modelGrid)
  
  for(i in 1:length(uniqueModels)){
    gID <- uniqueModels[i]
    
    # pull in training data 
    pfiles <- list.files(path = "data/raw",
                         pattern = paste0(gID,".geojson"),
                         full.names = TRUE,
                         recursive = TRUE)
    # pull in model results 
    rFiles <- list.files(path = paste0("data/products/models",year,"/maskedImages"),
                         pattern = paste0(gID,"_Masked"),
                         full.names = TRUE,
                         recursive = TRUE)
    if(length(pfiles) > 0 && length(rFiles)>0){
      # run intersection 
      p1 <- st_read(pfiles) |>
        dplyr::mutate(presence = case_when(
          presence == 1 ~ 1,
          TRUE ~ 0 
        ))|>
        terra::vect()
      r1 <- terra::rast(rFiles)
      # extract 
      p1$predictedValue <- terra::extract(r1, y = p1)[,2]
      # summarize 
      data <- p1 |>
        as.data.frame()|>
        summarise(
          # Count the four outcomes
          TP = sum(presence == 1 & predictedValue == 1, na.rm = TRUE),
          FN = sum(presence == 1 & predictedValue == 0, na.rm = TRUE),
          TN = sum(presence == 0 & predictedValue == 0, na.rm = TRUE),
          FP = sum(presence == 0 & predictedValue == 1, na.rm = TRUE),
          # Calculate the rates using the counts
          truePositiveRate = .data$TP / (.data$TP + .data$FN),
          trueNegitiveRate = .data$TN / (.data$TN + .data$FP)
        ) |>
        dplyr::mutate(year = year, 
                      model = gID)
      
      # set up storage 
      if(i == 1){
        output <- data 
      }else{
        output <- bind_rows(output,data)
      }
    }
  }
  return(output)
}
# 
allVals <- purrr::map(.x = c("2010","2016","2020"), .f = extractConMax) |>
  bind_rows() |>
  dplyr::select("model", "year","TP","FN","TN","FP","truePositiveRate","trueNegitiveRate")
# export 
write_csv(x = allVals, file = "data/processed/validationPoints/allPointsValidation_allYears.csv")


