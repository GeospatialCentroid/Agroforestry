
## 

pacman::p_load(terra, leaflet, dplyr, readr)
# read in all features ----------------------------------------------------
refCSV <- read_csv("data/processed/harmonizedImages/gridsToRework.csv")
# grid features 
fullGrids <- sf::st_read("data/processed/griddedFeatures/twelve_mi_grid_uid.gpkg")


# images 
images <- list.files(path = "data/processed/harmonizedImages",
                     pattern = ".tif",
                     full.names = TRUE)
images <- images[!grepl(pattern = "combined_", images)]
# filter to years 
y10 <- images[grepl(pattern = "2010.tif", images)]
y16 <- images[grepl(pattern = "2016.tif", images)]
y20 <- images[grepl(pattern = "2020.tif", images)]

# itorate over grids 
gridID <- refCSV$gridsToRework

# subset grids 
fGrid <- fullGrids[fullGrids$Unique_ID %in% gridID, ]
leaflet(fGrid) |>
  addProviderTiles("Esri.WorldImagery")|>
  addPolygons(color = "#444000", weight = 3, smoothFactor = 0.5,
              opacity = 1.0, 
              fillOpacity = 0.1,
              label = fGrid$Unique_ID)


for(year in c("2010", "2016", "2020")){
  im <- images[grepl(pattern = paste0(year,".tif"), images)]
  # select all grids of interest 
  
  for(id in gridID){
    # test to see if there are image for this grid 
    sel <- im[grepl(pattern = paste0(id,"_using"), x = im)]
    if(length(sel) >0 ){
      print(id)
      # get end file path 
      baseName <- basename(sel)
      # create raster object 
      r1 <- terra::rast(sel)
      # assing names 
      names(r1) <- baseName
      
      # Define the output PDF file name
      pdf_filename <- paste0( "data/processed/harmonizedCompare/raster_plots",id,"_",year,".pdf")
      
      # Open a PDF device to save the plots
      pdf(file = pdf_filename)
      
      # Set up the plotting layout for 2 rows and 2 columns
      par(mfrow = c(2, 2))
      # Loop through the list of rasters and plot each one
      for(r in baseName){
        current_raster <- r1[[r]]
        if(grepl(pattern = "ref_harmonized_map_b", r)){
          n <- "ref b"
        }
        if(grepl(pattern = paste0("ref_harmonized_map_",id) , r)){
          n <- "ref"
        }
        if(grepl(pattern = "self_harmonized_map_b", r)){
          n <- "self b"
        }
        if(grepl(pattern = paste0("self_harmonized_map_",id), r)){
          n <- "self"
        }
        plot(current_raster, main = n) # Use the raster name as the title
      }
      # Add a title to the entire page
      mtext(paste0(id,"_", year), side = 3, line = -2, outer = TRUE, cex = 1.5, font = 2)
      
      # Close the PDF device to save the file
      dev.off()
    }else{
      next()
    }
  }
} 



