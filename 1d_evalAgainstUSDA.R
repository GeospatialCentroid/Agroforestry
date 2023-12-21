###
# for selected areas, evaluated the exported image against the USDA reference data
# 
#
###

pacman::p_load(terra, dplyr, tools, tmap)

### the function works but I need to developed  
### a reference list of objects that are inside of the antelope county 
### a means of grabing all the files of interest to generate the map. 

# fileLocation <- "C:/Users/carverd/Documents/GitHub/Agroforestry/test10.tif"
# refFileLocation <-  "C:/Users/carverd/Documents/GitHub/Agroforestry/data/raw/referenceData/Antelope_ALL_metrics_LCC_edited.shp"
# exportFolder <- "C:/Users/carverd/Documents/GitHub/Agroforestry/data/processed/appliedModels/maps"

compareClassifications <- function(fileLocation, refFileLocation,exportfolder, compareUSDA){
  # grab file name from the file file location object 
  name <- tools::file_path_sans_ext(basename(fileLocatation))
  
  #classified data 
  c1 <- fileLocatation |>
    terra::rast()

  if(compareUSDA ==TRUE){
    # process the ref file location 
    ref1 <- refFileLocation |>
      terra::vect() |>
      terra::project(c1) |>
      terra::crop(ext(c1))
                     
      #reclassifiy and create a single object 
      # classified model 
      c1[is.nan(c1), ]<- 2
      c1[c1 == 1, ] <- 3
      
      # usda ref 
      ref2[is.nan(ref2), ]<- 5
      ref2[ref2==1, ]<- 7
      
      #combined layer 
      b1 <- c1 + ref2
      
      # make a map 
      map1 <- tm_shape(b1) + 
        tm_raster(n = 4,
                  title = name,
                  style = "cat",
                  palette = c('#ffffff','#ffff33',"#ff7f00","#4daf4a"),
                  labels = c("True Negitive", 
                             "False Positive",
                             "False Negitive",
                             "True Positive"))+
        tm_layout(legend.outside=TRUE, 
                  legend.outside.position="right")
      
      tmap_save(map1, paste0(exportFolder,"/",name,".png"), height=6, width=8)
  }else{
    ## if there is no USDA reference layer just export the image as a map. 
    c1[is.nan(c1),]<- 0
    # make a map 
    map1 <- tm_shape(c1) + 
      tm_raster(n = 2,
                title = name,
                style = "cat",
                palette = c('#ffffff',"#4daf4a"),
                labels = c("Not Trees", 
                           "Trees"))+
      tm_layout(legend.outside=TRUE, 
                legend.outside.position="right")
    
    tmap_save(map1, paste0(exportFolder,"/",name,".png"), height=6, width=8)
    
  }
}
