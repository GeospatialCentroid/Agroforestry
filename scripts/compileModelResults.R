# 

pacman::p_load(terra, sf, dplyr, googledrive,
               stringr,purrr,furrr, tigris, tictoc,
               tmap)
tmap::tmap_mode("view")

# pull in the specific model grid elements 
modelGrids <- list.files(path = "data/products", pattern = "modelGrids", full.names = TRUE)

# list files from from google drive
images <- googledrive::drive_ls(path = "agroforestry",pattern = ".tif")  |>
  dplyr::filter(!grepl('validationGrid', name))|>
  dplyr::filter(!grepl('naipGrid', name))
  

# riparian data download and project --------------------------------------
# riparian <- images[images$name == "nebraskaRiparian.tif", ]
# googledrive::drive_download(as_id(riparian$id),
#                             path = paste0("data/raw/riparian/riparianArea10.tif"))

# r10proj <- terra::rast("data/raw/riparian/riparianArea10.tif")|>
#   terra::project("+init=EPSG:4326")
# terra::writeRaster(r10proj ,
#                    filename = "data/products/riparian/nebraskaRiparian10.tif", 
#                    overwrite = TRUE)
# riparianRast30 <- terra::rast("data/raw/riparian/riparianArea30.tif")
# 
# r30proj <- riparianRast30 |>
#   terra::project("+init=EPSG:4326")
# terra::writeRaster(r30proj, filename = "data/products/riparian/nebraskaRiparian30.tif")
# 


# year <- "2020"
# 
# modelGrid <- modelGrids[grepl(pattern = year, x = modelGrids)] |> terra::vect()
# for each model grid test select all the included sub grid 




# download data from Drive function 

downloadFromDrive <- function(year, images, modelGrids){
  # select the grid of interest 
  modelGrid <- modelGrids[grepl(pattern = year, x = modelGrids)] |> terra::vect()
  
  # select images of interest 
  images2 <- images |> dplyr::filter(grepl(year, name))
  # get unique model grids 
  modelGrids <- unique(modelGrid$modelGrid)
  modelGrids <- modelGrids[!is.na(modelGrids)]
  
  # loop over each model grid 
  for(i in modelGrids[1:10]){
    imageSelected <- images2[grepl(pattern = i, x = images2$name),]
    gridSelect <- modelGrid[modelGrid$modelGrid == i, ]
    downloadPath <- paste0("data/products/models",year)
    for(j in seq_along(imageSelected$id)){
      id <- imageSelected$id[j]
      name <- imageSelected$name[j]
      # try statement it to help with the overwrite conditions 
      try(
        image <- googledrive::drive_download(as_id(id),
                                             path = paste0(downloadPath,"/",name))
      )
    }
  }
} 

# apply the download function  --------------------------------------------

# downloadFromDrive(year = "2020", images = images2020, modelGrids = modelGrids)
# downloadFromDrive(year = "2016", images = images, modelGrids = modelGrids)
# downloadFromDrive(year = "2010", images = images, modelGrids = modelGrids)


# function for cropping models to grids 

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


# Apply the masks and bind to full grid ------------------------------------
# read in mask layers

# testing 692
year <- "2020"
nlcdMasks <- list.files("data/products/nlcd",pattern = ".gpkg", full.names = TRUE, recursive = TRUE)
# tccs <- nlcdMasks[grepl(pattern = "tcc", nlcdMasks)]
forests <- nlcdMasks[grepl(pattern = "forest", nlcdMasks)]
# urban areas 
urbanFiles <- list.files("data/raw/censusData/", pattern = "*\\.shp", full.names = TRUE, recursive = TRUE )
urbanFiles2 <- urbanFiles[stringr::str_ends(string = urbanFiles, pattern = ".shp")]
# riparian zones 
# riparian <- terra::vect("data/raw/test.shp")
## need to get this cropped to nebraska and out of the GDB file structure 
# st_layers("data/raw/Data/RiparianAreas.gdb")
# rp <- sf::st_read("data/raw/Data/RiparianAreas.gdb", layer = "fras_blk_usfs_riparian_areas_1")

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


generateFinalGridImages <- function(year, modelGrids, forests, urbanFiles2){
  modelFolder <- paste0("data/products/models",year)
  # get all models for a year 
  models <- list.files(paste0(modelFolder,"/grids"), full.names = TRUE)
  # select images for specific grid 
  grids <- terra::vect(modelGrids[grepl(pattern = year, x = modelGrids)])
  # Select the forest and urban layers
  forest <- terra::vect(forests[grepl(pattern = year, x = forests)]) |>
    terra::project("+init=EPSG:4326")
  # terra::writeVector(forest, filename ="data/products/foresttest.gpkg" )
  urban <- terra::vect(urbanFiles2[grepl(pattern = year, x = urbanFiles2)])|>
    terra::project("+init=EPSG:4326")
  ## add the riparian layer once that is created 
  
  # select all unique grids 
  ids <- grids$Unique_ID
  # itorate over grids to produce outputs 
  for(i in ids[1:10]){
    allImages <- models[grepl(paste0("/",i,"_"), models)]
    gridName <- i 
    unmaskedPath <- paste0("data/products/models",year,"/fullImages/",gridName,"_fullUnMasked.tif")
    # if there are images 
    if(length(allImages) > 0){
      if(!file.exists(unmaskedPath)){
        origImages <- allImages[!grepl(pattern = "_b_", allImages )]
        for(j in seq_along(origImages)){
          print(origImages[j])
          print("producing model area")
          n1 <- basename(origImages[j]) |>
            str_split(pattern = "_") |> 
            unlist()
          n2 <- n1[3]
          # select all paths with this image name 
          r1 <- allImages[grepl(pattern = n2, x = allImages)]
          # generate rast object 
          r2 <- mergeClass(r1)
          if(j == 1){
            r3 <- r2
          }else{
            print(paste0("merging ", j))
            r3 <- merge(r3,r2)
          }
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
      }
    }else{
      print(paste0("no image for ",i))
    }
  }
}



generateFinalGridImages(year = "2020", 
                          modelGrids = modelGrids,
                          forests = forests, 
                          urbanFiles2 = urbanFiles2)

# applied the riparian area mask 
year = "2020"
riparianData = terra::rast("data/products/riparian/nebraskaRiparian10.tif")

applyRiparianMask <- function(year,riparianData){
  
  # set the based path for images 
  base <- paste0("data/products/models",year)
  
  # pull all masked images 
  files <- list.files(
    path = paste0(base, "/maskedImages"),
    full.names = TRUE,
    pattern = ".tif"
  )
  for(i in files){
    print(i)
    tic()
    image <- terra::rast(i)
    
    fileName <- paste0(base,"/maskedWithRiparian/",names(image), "_riparianClass.tif")
    if(!file.exists(fileName)){
      image[image == 0] <- NA
      # crop riparian layer 
      r30 <- terra::crop(x = riparianData,
                       y = image) |>
      terra::as.polygons()|>
      rasterize(image, values = 1, background = 0) 
    
      # mask to the origin image
      c2 <- r30 + image
    
      #export the image 
      terra::writeRaster(x = c2, 
                  filename = paste0(base,"/maskedWithRiparian/",names(image), "_riparianClass.tif"),
                  overwrite = TRUE)
    }else{
      print("file already exists")
    }
    toc()
  }
}

# apply the mask 
applyRiparianMask(year = "2020",
                  riparianData = riparianData )
