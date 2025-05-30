pacman::p_load(terra, furrr, tictoc,readr)

source("scripts/functions/reclassByYear.R")
cotFiles <- list.files(path = "data/products/changeOverTime",
                       pattern = "_2.tif",
                        full.names = TRUE )

grids <- terra::vect(x = "data/processed/griddedFeatures/twelve_mi_grid_uid.gpkg" )

gridIDs <- unique(grids$Unique_ID)

gridID <- gridIDs[560]
# f2 <- list.files(path = "data/products/imagesOfResults",
#                  pattern = ".csv",
#                  full.names = TRUE)
# file.remove(f2)

# spliting this out to two functions 
# 1 generate the tabular data 
# 2 generate the plots 

calculateArea <- function(gridID, grids, cotFiles){
  print(gridID)
  # csv
  exportPath <- paste0("data/products/imagesOfResults/",gridID,"_cot.csv")
  if(!file.exists(exportPath)){
    # select the file based on gridID
    f1 <- cotFiles[grepl(pattern = paste0(gridID,"_c"), x = cotFiles)]
    # if(length(f1)==0) 
    r1 <- terra::rast(f1)
    # reclass to year 
    y10 <- getYearMap(r1, 2010) 
    area10 <- y10|>
      terra::expanse(unit = "m", byValue = TRUE)
    freq10 <- terra::freq(y10)
    rm(y10)
    
    y16 <- getYearMap(r1, 2016)
    area16 <- y16 |>
      terra::expanse(unit = "m", byValue = TRUE)
    freq16 <- terra::freq(y16)
    rm(y16)
    
    y20 <- getYearMap(r1, 2020)
    area20 <- y20|>
      terra::expanse(unit = "m", byValue = TRUE)
    freq20 <- terra::freq(y20)
    rm(y20)
    # 
    rm(r1)
    # add values to dataframe 
    df <- data.frame(
      gridID = gridID,
      area10 = area10[area10$value==1 , "area"],
      area16 = area16[area16$value==1 , "area"],
      area20 = area20[area20$value==1 , "area"],
      cell10 = freq10[freq10$value==1, "count"],
      cell16 = freq16[freq16$value==1, "count"],
      cell20 = freq20[freq20$value==1, "count"]
    )
    #export 
    readr::write_csv(df, exportPath)
  }
  gc()
}

  
generatePlots <- function(gridID, grids, cotFiles){
  print(gridID)
  # csv
  exportPath <- paste0("data/products/imagesOfResults/",gridID,"_cot.pdf")
  if(!file.exists(exportPath)){
    # select the file based on gridID
    f1 <- cotFiles[grepl(pattern = paste0(gridID,"_c"), x = cotFiles)]
    # if(length(f1)==0) 
    r1 <- terra::rast(f1)
    # reclass to year 
    y10 <- getYearMap(r1, 2010) 
    y16 <- getYearMap(r1, 2016)
    y20 <- getYearMap(r1, 2020)
    # 
    rm(r1)
    # Open a PDF device to save the plots
    pdf(file = exportPath)
    
    # Set up the plotting layout for 2 rows and 2 columns
    par(mfrow = c(1, 3))
    # Loop through the list of rasters and plot each one
    for(r in 1:3){
        if(r == 1){
          n <- "2010"
          current_raster <- y10
        }
        if(r == 2){
          n <- "2016"
          current_raster <- y16
          }
          if(r == 3){
            n <- "2020"
            current_raster <- y20
          }
          plot(current_raster, main = n) # Use the raster name as the title
        }
        # Add a title to the entire page
        mtext(paste0(gridID," Yearly Maps"), side = 3, line = -2, outer = TRUE, cex = 1.5, font = 2)
        
        # Close the PDF device to save the file
        dev.off()
        rm(y10)
        rm(y16)
        rm(y20)
  }
  gc()
}

# apply 
# gridID <- "X12-772"
# generatePlots(gridID = gridID, grids = grids, cotFiles = cotFiles)

future::plan("multicore", workers = 6)
# future::plan("sequential")
# plots
tic()
furrr::future_map(.x = gridIDs, .f = generatePlots,
                  grids = grids,
                  cotFiles = cotFiles)
toc()

# future::plan("sequential")
# area measurements  
calculateArea(gridID = "X12-772", grids = grids, cotFiles = cotFiles)

tic()
furrr::future_map(.x = gridIDs, .f = calculateArea,
                  grids = grids,
                  cotFiles = cotFiles)
toc()



# read in data and summarise
# d1 <- list.files(path = "data/products/imagesOfResults",
#                  pattern = "_cot.csv",
#                  full.names = TRUE) |>
#   readr::read_csv()
# dim(d1)
# View(d1)
# readr::write_csv(x = d1, file = "data/products/imagesOfResults/allAreaMeasures.csv")

# few with 0 vaules across the board. 
# errors <- d1[d1$area10==0,]
# # files 
# allFiles <- list.files("data/products/imagesOfResults",
#                        full.names = TRUE)
# for(i in errors$gridID){
#   r <- allFiles[grepl(pattern = paste0(i,"_cot"), allFiles)]
#   file.remove(r)
# }
