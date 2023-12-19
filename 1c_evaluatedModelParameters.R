###
# functions to 
#
#
### 

# parse out the [[]] columns and generate some confusion matrix statistics 
generateConfusionMatrixStats <- function(data){
  d2 <- data |>
    dplyr::mutate(allValuesTrim = stringr::str_remove_all(allValues, pattern =  "\\[")) |>
    dplyr::mutate(allValuesTrim = stringr::str_remove_all(allValuesTrim, pattern =  "\\]"))|>
    tidyr::separate(col = allValuesTrim, 
                    into = c("trueNegitive", "falsePositive", "falseNegitive", "truePositive"),
                    sep = ",")|>
    dplyr::mutate_at(c("trueNegitive", "falsePositive", "falseNegitive", "truePositive"), as.numeric) |> 
    dplyr::mutate(
      truePositiveRate = truePositive/(truePositive+falseNegitive),
      trueNegitiveRate = trueNegitive/(trueNegitive + falsePositive)
    )
  return(d2)
}


relativePath <- "data/processed/parameterTesting"
outputfilename <- paste0("gatheredData_", Sys.Date())

compileCSVS <- function(relativePath, outputfilename){
  library(readr)
  library(dplyr)
  library(purrr)
  # produce the full dataset ------------------------------------------------
  # define path
  wd <- getwd()
  path <- paste0(wd,"/",relativePath) 
  # read in files 
  files <- list.files(path = path,
                      pattern = "*.csv",
                      full.names = TRUE)
  
  # read and bind the dataframes 
  data <- files |>
    purrr::map(read_csv) |>
    dplyr::bind_rows() |>
    generateConfusionMatrixStats()
  
  # export file 
  readr::write_csv(x = data, file = paste0(wd,"/",relativePath,"/combinedData/", outputfilename))
  
  return(data)
}


# run the process 
data <- compileCSVS(relativePath = relativePath,
                    outputfilename = outputfilename)









data# generate plots 
parameters <- c("SNIC_SuperPixelSize", "SNIC_SeedShape", "SNIC_Compactness","SNIC_Connectivity")

generatePlots <- function(relativePath, parameters){
  library(readr)
  library(dplyr)
  library(purrr)
  library(plotly)
  # define path
  wd <- getwd()
  path <- paste0(wd,"/",relativePath) 
  
  # read in files 
  files <- list.files(path = path,
                      pattern = "*.csv",
                      full.names = TRUE)
  
  for(i in parameters){
    f2 <- files[grepl(pattern = i, x = files)]
    # read and bind the dataframes 
    d2 <- f2 |>
      purrr::map(read_csv) |>
      dplyr::bind_rows() |>
      generateConfusionMatrixStats()
    
    d2$xVal <- d2[,names(d2)==i] |> pull()
    xVal <- d2[,names(d2)==i] |> sort()
    
    # plot the false posivity rate, fasle negtive rate, and the overall accuracy for each value 
    fig <- plot_ly(data = d2, x = ~xVal) |>
      add_trace(y = ~overallAccuracy, name = 'Overall Accuracy',mode = 'markers')|>
      add_trace(y = ~truePositiveRate, name = 'True Positive Rate',mode = 'markers') |>
      add_trace(y = ~trueNegitiveRate, name = 'True Negitive Rate',mode = 'markers')
    # add the x label and set the extent of the x axis to zero
    # need to figure out how to pass a generic column name to the xaxis
    
  }
  
}
 