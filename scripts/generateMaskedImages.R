
pacman::p_load(terra,dplyr,readr,sf,furrr)
# Apply the masks and bind to full grid ------------------------------------
# read in mask layers

# testing 6 
year <- "2010"
nlcdMasks <- list.files("data/products/nlcd",pattern = ".gpkg", full.names = TRUE, recursive = TRUE)
# tccs <- nlcdMasks[grepl(pattern = "tcc", nlcdMasks)]
forests <- nlcdMasks[grepl(pattern = "forest", nlcdMasks)]
# urban areas 
urbanFiles <- list.files("data/products/censusData/", pattern = "*\\.shp", full.names = TRUE, recursive = TRUE )
urbanFiles2 <- urbanFiles[stringr::str_ends(string = urbanFiles, pattern = ".shp")]

modelGrids <- sf::st_read("data/processed/griddedFeatures/twelve_mi_grid_uid.gpkg")


# interatre
mergeClass <- function(listOfImages){
  if(length(listOfImages) ==2){
    # add the images 
    r3 <- rast(listOfImages[1]) + rast(listOfImages[2])
    r4 <- ifel(r3 <= 1, 0 , 1)
  }else{
    r4 <- rast(listOfImages[1])
  }
  return(r4)
}

year <- 2010


generateFinalGridImages <- function(year, modelGrids, forests, urbanFiles2){
  modelFolder <- paste0("data/products/models",year)
  # get all models for a year 
  models <- list.files(paste0(modelFolder,"/fullImages"), full.names = TRUE)
  # # select images for specific grid 
  # grids <- terra::vect(modelGrids[grepl(pattern = year, x = modelGrids)])

  ## add the riparian layer once that is created 
  
  # select all unique grids 
  ids <- modelGrids$Unique_ID
  # troubleshooting
  # ids <- c("X12-515")
  
  
  # itorate over grids to produce outputs 
  for(i in ids){
    allImages <- models[grepl(paste0("/",i,"_"), models)]
    
    gridName <- i 
    print(i)
    # unmaskedPath <- paste0("data/products/models",year,"/fullImages/",gridName,"_fullUnMasked.tif")
    # using the harmonized image for 2010 error resolution 
    unmaskedPath <- paste0("data/products/models",year,"/fullImages/",gridName,"_harmonized_fullUnMasked.tif")
    
    # if there are images 
    if(length(allImages) > 0){
      if(!file.exists(unmaskedPath)){
        origImages <- allImages[!grepl(pattern = "_b_", allImages )]
        if(length(origImages) < 2){
          r3 <- terra::rast(origImages)
        }else{
          # for handling the _b models 
          # for(j in seq_along(origImages)){
          #   print(origImages[j])
          #   print("producing model area")
          #   n1 <- basename(origImages[j]) |>
          #     str_split(pattern = "_") |> 
          #     unlist()
          #   n2 <- n1[3]
          #   # select all paths with this image name 
          #   r1 <- allImages[grepl(pattern = n2, x = allImages)]
          #   # generate rast object 
          #   r2 <- mergeClass(r1)
          #   if(j == 1){
          #     r3 <- r2
          #   }else{
          #     print(paste0("merging ", j))
          #     r3 <- merge(r3,r2)
          #   }
          # }
        }
        
        # set the name of the object 
        rastName <-  paste0(gridName,"_",year)
        names(r3) <-rastName
        # export 
        try(terra::writeRaster(x = r3, filename = unmaskedPath, overwrite = TRUE ))
      }else{
        r3 <- terra::rast(unmaskedPath)
      }
      # produce a mask object
      maskedPath <- paste0("data/products/models",year,"/maskedImages/",gridName,"_Masked.tif")
      if(!file.exists(maskedPath)){
        # Select the forest and urban layers
        forest <- terra::vect(forests[grepl(pattern = year, x = forests)]) |>
          terra::project("+init=EPSG:4326")
        # terra::writeVector(forest, filename ="data/products/foresttest.gpkg" )
        urban <- terra::vect(urbanFiles2[grepl(pattern = year, x = urbanFiles2)])|>
          terra::project("+init=EPSG:4326")
        
        print("generating mask")
        #  nlcd tree mask 
        ## something going on the with forest mask not getting applied 
        f2 <-  forest |>
          crop(r3) |>
          rasterize(r3, values = 1) 
        
        if(class(f2)=="SpatRaster"){
          r4 <- terra::mask(x = r3, mask = f2, inverse = TRUE, updatevalue=NA)
        }else{
          r4 <- r3
        }
        
        # town mask 
        t2 <- urban |> 
          crop(r3)
        if(nrow(t2)!=0){
          print("removing town")
          t3 <- t2 |> rasterize(r3, values = 1) 
          r4 <- r4 |>
            terra::mask(t3, inverse = TRUE, updatevalue=NA)
        }
        # export the masked image 
        try(terra::writeRaster(x = r4, filename = maskedPath ))
        rm(t2)
        rm(t3)
        rm(f2)
        rm(r4)
        rm(r3)
        rm(forest)
        rm(urban)
      }
    }else{
      print(paste0("no image for ",i))
    }
  }
  gc()
}


# all 2010 data needs to be regenerated 
years <- c("2010", "2016","2020") 

# troubleshooting 
# modelGrids <- "X12-183"
modelGrids <- modelGrids[ modelGrids$Unique_ID %in% c("X12-319","X12-366",  "X12-367","X12-413",  "X12-513","X12-514", 
                           "X12-515","X12-516",  "X12-517","X12-559",  "X12-560","X12-561", 
                           "X12-562","X12-563",  "X12-604","X12-605",  "X12-606","X12-607",  
                           "X12-608","X12-649",  "X12-650","X12-651",  "X12-652","X12-653",  
                           "X12-694","X12-695",  "X12-696","X12-697",  "X12-698") ,] 


for(i in years){
  print(i)
  generateFinalGridImages(year = "2010", 
                          modelGrids = modelGrids,
                          forests = forests, 
                          urbanFiles2 = urbanFiles2)
}

