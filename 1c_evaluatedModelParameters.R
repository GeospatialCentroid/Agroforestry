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









# generate plots 
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
  
  figs <- list()
  
  for(i in seq_along(parameters)){
    name = parameters[i]
    
    f2 <- files[grepl(pattern = name, x = files)]
    # read and bind the dataframes 
    d2 <- f2 |>
      purrr::map(read_csv) |>
      dplyr::bind_rows() |>
      generateConfusionMatrixStats()
    
    # set the x value data of interest to a standard column name for ploting
    d2$xVal <- d2[,names(d2)==name] |> pull()
    
    # plot the false posivity rate, fasle negtive rate, and the overall accuracy for each value 
    fig <- plot_ly(data = d2, x = ~xVal) |>
      add_trace(y = ~overallAccuracy, name = 'Overall Accuracy',mode = 'markers', type = "scatter")|>
      add_trace(y = ~truePositiveRate, name = 'True Positive Rate',mode = 'markers', type = "scatter") |>
      add_trace(y = ~trueNegitiveRate, name = 'True Negitive Rate',mode = 'markers', type = "scatter")|>
      layout(title = paste0('Accuracy Plots of ',name),
              plot_bgcolor = "#e5ecf6", 
              xaxis = list(title = name), 
             yaxis = list(title = 'Accuracy',
                          range=c(0,1.1)), 
             legend = list(title=list(text='<b> Measures of Accuracy </b>')))
    
    
    figs[[i]]<-fig
    
    
  }
  return(figs)
}

plots <- generatePlots(relativePath = relativePath,
              parameters = parameters)
 