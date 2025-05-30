pacman::p_load(terra,dplyr,stringr,purrr,furrr, tictoc)


# applied the riparian area mask 
year = "2016"
riparianData = terra::rast("data/products/riparian/nebraskaRiparian10.tif")
# 
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
    # grad specific grid name 
    name <- basename(i) |>
      stringr::str_split("_")|>
      unlist()
    
    tic()
    image <- terra::rast(i)
    fileName <- paste0(base,"/maskedWithRiparian/",name[1],"_",year, "_riparianClass.tif")
    if(!file.exists(fileName)){
      print(fileName)
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
                         filename = fileName,
                         overwrite = TRUE)
      rm(c2)
      rm(r30)
      rm(image)
    }else{
      print("file already exists")
    }
    toc()
  }
  gc()
}

# apply the mask 
# applyRiparianMask(year = "2010",
#                   riparianData = riparianData )
future::plan("multicore", workers = 2)
# future::plan("sequential")

furrr::future_map(.x = c("2010","2016","2020"), .f = applyRiparianMask,
                  riparianData = riparianData,
                  .progress = TRUE)





# render full year riparian mask  -----------------------------------------

# for processing 
## end up with 6 layers 3 riparian mask, 3 new value class 

renderFullRiparianMask <- function(grid, files){
  
  exportPath <- paste0("data/products/riparian/allYears/riparianMask_",grid,".tif")
  
  print(grid)
  if(!file.exists(exportPath)){
    # filter and read in images 
    f1 <- files[grepl(pattern = paste0(grid,"_"), x = files)]
    
    # need condition in here for selecting the harmonized models then rep
    f2 <- f1[grepl(pattern = "harmonized", f1)]
    harmonized <- FALSE
    if(length(f2) >= 1){
      harmonized <- TRUE
      if(length(f2) == 3){
        f1 <- f2
        allHarmonized <- TRUE
      }else{
        allHarmonized <- FALSE
        # remove all non harmonized options 
        basenames <- basename(f2) 
        if(grepl(pattern = "2020", x = basenames)){
          f1 <- f1[!grepl(pattern = paste0(grid,"_2020"), f1)]
        }
        if(grepl(pattern = "2016", x = basenames)){
          f1 <- f1[!grepl(pattern = paste0(grid,"_2016"), f1)]
        }
        if(grepl(pattern = "2010", x = basenames)){
          f1 <- f1[!grepl(pattern = paste0(grid,"_2010"), f1)]
        }
        
      }
      
      
    }else{
      harmonized <- FALSE
    }
    
    
    if(length(f1) > 0){
      
      # reclass function 1 
      reclas <- function(raster){
        ifel(raster == 2, 1 , 0)
      }
      # gather and reclass layers 
      r1 <- lapply(X = f1, FUN = terra::rast) |>
        purrr::map(.f = reclas)
      # if crop all if harmonized image is present 
      if(harmonized == TRUE){
        cropper <- terra::rast(f2[1])
        r1 <- r1 |> 
          purrr::map(crop, cropper)
        rm(cropper)
        if(allHarmonized == FALSE){
          # select a non harmonized image for croping
          cropper1 <- terra::rast(f1[grepl(pattern = paste0(grid,"_20"), x = f1)][1])
          r1 <- r1 |>
            purrr::map(crop, cropper1)
          rm(cropper1)
        }
      }else{
        ext1 <- lapply(X = r1, FUN = terra::ncell) |>unlist()
        # select the min area
        cropper1 <- r1[ext1 == min(ext1)] |>rast()
        
        r1 <- r1 |>
          purrr::map(crop, cropper1)
        rm(cropper1)
      }
      
      # add them all together
      r2 <- terra::app(x = terra::rast(r1), fun = sum, na.rm = TRUE)
      rm(r1)
      # reclass and export
      r3 <- terra::ifel(r2 >0, 1 , NA)
      terra::writeRaster(x = r3, filename = exportPath)
    }
  }
  gc()
}




# render riparian  --------------------------------------------------------
print("generating Riparain Mask")
# issues with memory allocation on X12-319 
grids <- grids <- paste0("X12-", 1:773)
files <- list.files(path = "data/products", 
                    pattern = "_riparianClass.tif",
                    full.names = TRUE,
                    recursive = TRUE)

# single feature 
# renderFullRiparianMask(grid = "X12-369", files = files)

# all features 
for(i in grids){
  print(i)
  renderFullRiparianMask(grid = i, files = files)
}

# memory allocation is a bit to high for this.... 
# future::plan("multicore", workers = 2)
# # future::plan("sequential")
# furrr::future_map(.x = grids, .f = renderFullRiparianMask,
#                           files = files)

