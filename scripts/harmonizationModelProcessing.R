pacman::p_load(terra,dplyr,readr, purrr, furrr)


# reference information 
ref <- read_csv("data/processed/harmonizedImages/siteSelection.csv")

images <- list.files(path = "data/processed/harmonizedImages",
                     pattern = ".tif",
                     full.names = TRUE)
year <- 2016
gridID <- 155
# make a combination image and export to fullImages folder 
generateFullImage <- function(gridID, year, ref, images){
  # export path 
  exportPath <- paste0("data/products/models",year,"/fullImages/X12-",gridID,"_fullUnMasked.tif")
  print(gridID)
  if(!file.exists(exportPath)){
    # select row 
    d1 <- ref[ref$year == year, ]
    d1 <-d1[d1$gridID == gridID, ]
    # filer images to year 
    i1 <- images[grepl(paste0("_",year,".tif"), x = images)]
    #filter to grid 
    i2 <- i1[grepl(paste0(gridID,"_using"), i1)]
    
    # select
    feat1 <- d1$model1
    feat2 <- d1$model2
    if(feat1 == "ref"){
      r1 <- terra::rast(i2[grepl(pattern ="ref_harmonized_map_X12", i2)])
    }
    if(feat1 == "ref b"){
      r1 <- terra::rast(i2[grepl(pattern ="ref_harmonized_map_b_X12", i2)])
    }
    if(feat1 == "self"){
      r1 <- terra::rast(i2[grepl(pattern ="self_harmonized_map_X12", i2)])
    }
    if(feat1 == "self b"){
      r1 <- terra::rast(i2[grepl(pattern ="self_harmonized_map_b_X12", i2)])
    }
    # relclass raster 
    r1 <- terra::subst(x = r1, from =  0, to = NA)
    
    if(!is.na(feat2)){
      if(feat2 == "ref"){
        r2 <- terra::rast(i2[grepl(pattern ="ref_harmonized_map_X12", i2)])
      }
      if(feat2 == "ref b"){
        r2 <- terra::rast(i2[grepl(pattern ="ref_harmonized_map_b_X12", i2)])
      }
      if(feat2 == "self"){
        r2 <- terra::rast(i2[grepl(pattern ="self_harmonized_map_X12", i2)])
      }
      if(feat2 == "self b"){
        r2 <- terra::rast(i2[grepl(pattern ="self_harmonized_map_b_X12", i2)])
      }
      
      # relclass raster 
      r2 <- terra::subst(x = r2, from =  0, to = NA)
      # combine and reclass
      r3 <- r1 + r2
      r3 <- terra::subst(x = r3, from =  2, to = 1)
      rm(r2)
      rm(r1)
    }else{
      r3 <- r1
    }
    # export 
    terra::writeRaster(x = r3, filename = exportPath, overwrite = TRUE)
  }else{
    print("file exists")
  }
}


# render process 
g10 <- ref$gridID[ref$year == 2010]
g10 <- g10[g10 != 336]
g16 <- ref$gridID[ref$year == 2016]
# removing error features 
g16 <- g16[g16 != 98]
g20 <- ref$gridID[ref$year == 2020]
g20 <- g20[g20 != 179]


for(i in g10){
  generateFullImage(gridID = i, year = 2010,
                    ref = ref, images = images)
}
for(i in g16){
  generateFullImage(gridID = i, year = 2016,
                    ref = ref, images = images)
}
for(i in g20){
  generateFullImage(gridID = i, year = 2020,
                    ref = ref, images = images)
}


plan(multicore, workers = 4)

# 2010
furrr::future_map(.x = g10, .f = generateFullImage,
                  year = 2010,
                  ref = ref,
                  images= images)

#2016
furrr::future_map(.x = g16, .f = generateFullImage,
                  year = 2016,
                  ref = ref,
                  images= images)

# 2020
furrr::future_map(.x = g20, .f = generateFullImage,
                  year = 2020,
                  ref = ref,
                  images= images)



## Altering Mask for Harmonized images  ------------------------------------
# modelGrids <- list.files(path = "data/products", pattern = "modelGrids", full.names = TRUE)
# year <- "2016"
# nlcdMasks <- list.files("data/products/nlcd",pattern = ".gpkg", full.names = TRUE, recursive = TRUE)
# # tccs <- nlcdMasks[grepl(pattern = "tcc", nlcdMasks)]
# forests <- nlcdMasks[grepl(pattern = "forest", nlcdMasks)]
# # urban areas 
# urbanFiles <- list.files("data/products/censusData/", pattern = "*\\.shp", full.names = TRUE, recursive = TRUE )
# urbanFiles2 <- urbanFiles[stringr::str_ends(string = urbanFiles, pattern = ".shp")]
# # 
# # interatre
# mergeClass <- function(listOfImages){
#   if(length(listOfImages) ==2){
#     # add the images 
#     r3 <- rast(listOfImages[1]) + rast(listOfImages[2])
#     r4 <- ifel(r3 <= 1, 0 , 1)
#   }else{
#     r4 <- rast(listOfImages[1])
#   }
#   return(r4)
# }
# 
# # list of features work reprocess 
# # modelGridsID <- read.csv("data/processed/harmonizedImages/gridsToRework.csv")
# modelGrids <- paste0("X12-", 1:733)
# 
# generateFinalGridImagesHarmonized <- function(year, modelGrids, forests, urbanFiles2){
#   modelFolder <- paste0("data/processed/combinedHaromized")
#   # get all models for a year 
#   models <- list.files(modelFolder, full.names = TRUE)
#   # filter to year 
#   mYear <- models[grepl(pattern = paste0("_",year,".tif"), x = models)]
#   # get unique grid ID
#   basenames <- basename(mYear) |>
#     stringr::str_split( pattern = "_")
#   
#   ids <- lapply(basenames, function(feature) {
#     if (length(feature) >= 2) {
#       return(feature[[1]])
#     } else {
#       return(NA) # Or some other indicator if the feature doesn't have 6 elements
#     }
#   }) |> unlist()|> unique()
#   
#   # select images for specific grid 
#   grids <- terra::vect(modelGrids[grepl(pattern = year, x = modelGrids)])
#   # Select the forest and urban layers
#   forest <- terra::vect(forests[grepl(pattern = year, x = forests)]) |>
#     terra::project("+init=EPSG:4326")
#   # terra::writeVector(forest, filename ="data/products/foresttest.gpkg" )
#   urban <- terra::vect(urbanFiles2[grepl(pattern = year, x = urbanFiles2)])|>
#     terra::project("+init=EPSG:4326")
#   ## add the riparian layer once that is created 
#   
#   # itorate over grids to produce outputs 
#   for(i in ids){
#     print(i)
#     allImages <- mYear[grepl(pattern = paste0(i,"_"),  mYear)]
#     gridName <- paste0(i,"_harmonized") 
#     unmaskedPath <- paste0("data/products/models",year,"/fullImages/",gridName,"_fullUnMasked.tif")
#     # if there are images 
#     if(length(allImages) > 0){
#       if(!file.exists(unmaskedPath)){
#         r3 <- terra::rast(allImages)[[1]] # some images ending up with two layers 
#         # reclass -- pulled out for troubleshooting
#         r3 <- r3 |> 
#           terra::subst(NA,0)|>
#           terra::subst(2,1)
#         # set the name of the object 
#         rastName <-  paste0(gridName,"_",year)
#         names(r3) <- rastName
#         # reclass to 0 and 1
#         
#         # export 
#         try(terra::writeRaster(x = r3, filename = unmaskedPath, overwrite = TRUE ))
#       }else{
#         r3 <- terra::rast(unmaskedPath)
#       }
#       # produce a mask object
#       maskedPath <- paste0("data/products/models",year,"/maskedImages/",gridName,"_Masked.tif")
#       if(!file.exists(maskedPath)){
#         print("generating mask")
#         #  nlcd tree mask 
#         ## something going on the with forest mask not getting applied 
#         f2 <-  forest |>
#           crop(r3) |>
#           rasterize(r3, values = 1) 
#         
#         if(class(f2)=="SpatRaster"){
#           r4 <- terra::mask(x = r3, mask = f2, inverse = TRUE, updatevalue=NA)
#         }else{
#           r4 <- r3
#         }
#         
#         # town mask 
#         t2 <- urban |> 
#           crop(r3)
#         if(nrow(t2)!=0){
#           print("removing town")
#           t3 <- t2 |> rasterize(r3, values = 1) 
#           r4 <- r4 |>
#             terra::mask(t3, inverse = TRUE, updatevalue=NA)
#         }
#         # export the masked image 
#         try(terra::writeRaster(x = r4, filename = maskedPath ))
#       }
#     }else{
#       print(paste0("no image for ",i))
#     }
#   }
# }
# 
# 
# for(i in c("2016", "2020")){
#   generateFinalGridImagesHarmonized(year = i, 
#                                     modelGrids = modelGrids,
#                                     forests = forests, 
#                                     urbanFiles2 = urbanFiles2)
# }