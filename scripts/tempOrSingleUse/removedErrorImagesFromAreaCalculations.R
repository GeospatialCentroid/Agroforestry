
pacman::p_load(terra, dplyr, readr)

d1 <- read_csv("data/products/imagesOfResults/allAreaMeasures.csv")

errorGrids <- d1[d1$area10 == 0, ]

gatherPaths <- function(year, folder){
  path <- paste0("data/products/models",year,"/",folder)
  
  paths <- list.files(path = path,
                      full.names = TRUE)
  return(paths)
}


# these need to be remove from Change over time and, maskedImages per year, masked with riparian 
### COT 
cot <- list.files(path = "data/products/changeOverTime",
                  pattern = "_2.tif",
                  full.names = TRUE)

# masked 

fullImages <- purrr::map(.x = c(2010,2016,2020), .f = gatherPaths,
                     folder = "fullImages") |> unlist()

masked <- purrr::map(.x = c(2010,2016,2020), .f = gatherPaths,
                     folder = "maskedImages") |> unlist()

maskedRiparian <- purrr::map(.x = c(2010,2016,2020), .f = gatherPaths,
                     folder = "maskedWithRiparian") |> unlist()

for(i in errorGrids$gridID){
  # cot 
  c1 <- cot[grepl(pattern = paste0(i,"_"), x = cot)]
  if(length(c1)>0){
    file.remove(c1)
  }
  # full images 
  f1 <- fullImages[grepl(pattern = paste0(i,"_"), x = fullImages)]
  if(length(f1)>0){
    file.remove(f1)
  }
  # full images harmonized  
  f1 <- fullImages[grepl(pattern = paste0(i,"_"), x = fullImages)]
  if(length(f1)>0){
    file.remove(f1)
  }
  # masked 
  m1 <- masked[grepl(pattern = paste0(i,"_"), x = masked)]
  if(length(m1)>0){
    file.remove(m1)
  }
  # masked Riparian 
  m2 <- maskedRiparian[grepl(pattern = paste0(i,"_"), x = maskedRiparian)]
  if(length(m2)>0){
    file.remove(m2)
  }
}

