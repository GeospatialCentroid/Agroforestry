# 

pacman::p_load(terra, sf, dplyr, googledrive,
               stringr,purrr,furrr, tigris, tictoc,
               tmap)
tmap::tmap_mode("view")

# pull in the specific model grid elements 
modelGrids <- list.files(path = "data/products", pattern = "modelGrids", full.names = TRUE)
mg20 <- sf::st_read(modelGrids[3]) 
library(tmap)
tmap_mode("view")
qtm(mg20)
# list files from from google drive
images <- googledrive::drive_ls(path = "agroforestry",pattern = ".tif")  |>
  dplyr::filter(!grepl('validationGrid', name))|>
  dplyr::filter(!grepl('naipGrid', name))
  



processToGrids <- function(year, modelGrids){
  
  # select model grids 
  modelGrid <- modelGrids[grepl(pattern = year, x = modelGrids)] |> terra::vect()
  
  uniqueGrid <- unique(modelGrid$modelGrid)
  g12 <- as.data.frame(modelGrid)
  uniqueGrid <- uniqueGrid[!is.na(uniqueGrid)] 
  
  # set the file locations 
  downloadPath <- paste0("data/products/models",year)
  productsPath <- paste0(downloadPath, "/grids")
  
  for(i in uniqueGrid){
    downloadedFiles <- list.files(downloadPath, pattern = i,full.names = TRUE )
    # subset spatial feature 
    g1 <- modelGrid[modelGrid$modelGrid ==i, ]
    # gather all individual model grids 
    subGrids <- as.data.frame(g1) |>
      dplyr::select(Unique_ID) |>
      pull()
    # loop over each downloaded file and generate subgrid datasets 
    for(j in downloadedFiles){
      # read in the specific image 
      rast <- terra::rast(j)
      # gather the model output name
      k2 <- stringr::str_split(j, pattern = "/")[[1]][4]
      for(k in subGrids){
        g2 <- g1[g1$Unique_ID == k,]
        r1 <- NA
        # set file path to check for existing files 
        n1 <- paste0(productsPath, "/", k, "_",k2)
        if(!file.exists(n1)){
        try(r1 <- terra::crop(x = rast, y = g2))
        if(class(r1) == "SpatRaster"){
            try(terra::writeRaster(x = r1, filename = n1))
          }
        }
      }
    }
  } 
}


# Process all sub grid data  ----------------------------------------------
# for(i in c("2010","2016","2020")){
#   processToGrids(year = i, modelGrids = modelGrids)
#}
# didn't really test but I think it'll work 
# set session info 
# plan(multicore, workers = 12)
# furrr::future_map(.x = c("2010","2016","2020"), .f = processToGrids, modelGrids = modelGrids)


# incomplete as written...  -----------------------------------------------


 
modelGrids <- paste0("X12-", 337:733)
# troubleshooting 
modelGrids <- "X12-336"
years <- c("2010", "2016", "2020")
for(year in years){
  print(year)
  # 
  modelFolder <- paste0("data/products/models",year,"/grids")
  # get all models for a year 
  models <- list.files(modelFolder, full.names = TRUE)
  
  for(i in modelGrids){
    print(i)
    allImages <- models[grepl(pattern = paste0("/",i,"_"),  models)]
    # split out 1st and B run models 
    ma <- allImages[!grepl(pattern = "_b_", allImages)]
    b <- allImages[grepl(pattern = "_b_", allImages)]
    
    
    unmaskedPath <- paste0("data/products/models",year,"/fullImages/",i,"_fullUnMasked.tif")
    # unmaskedPathB <- paste0("data/products/models",year,"/fullImages/",i,"_b_fullUnMasked.tif")
    
    if(!file.exists(unmaskedPath)){
      # test for a and b models 
      aModel <- NA
      bModel <- NA
      if(length(ma)>0){
        aModel <- terra::rast(ma)[[1]]
      }
      if(length(b)>0){
        bModel <- terra::rast(b)[[1]]
      }
      ## combine if two are present
      if(class(aModel)== "SpatRaster" & class(bModel) == "SpatRaster"){
        r1 <- aModel + bModel
        print("combining models")
        # reclass 
        r1 <- r1 |> 
          terra::subst(1,0)|>
          terra::subst(2,1)
        # export 
        terra::writeRaster(x = r1, 
                           filename = unmaskedPath, overwrite = TRUE)
      }else{
        if(class(aModel) == "SpatRaster"){
          
          print("exporting A model")
          terra::writeRaster(x = aModel, 
                             filename = unmaskedPath, overwrite = TRUE)
        }else{
          print("exporting B model")
          terra::writeRaster(x = bModel, 
                             filename = unmaskedPath, overwrite = TRUE)
        }
      }
    }
  } 
}
