
## 

pacman::p_load(terra, leaflet, dplyr, readr)
# read in all features ----------------------------------------------------
refCSV <- read_csv("data/processed/harmonizedImages/gridsToRework.csv")
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
grids <- refCSV$gridsToRework

g1 <- grids[38]

# test to see if there 
sel <- y10[grepl(pattern = g1, x = y10)]

names <- basename(sel)

rast <- terra::rast(sel)
names(rast) <- names

maps <- leaflet() |> leaflet() |>
  setView(lng = 0, lat = 0, zoom = 2)|> # Set initial view
  # Add the first raster layer
  addRasterImage(r1, color = pal1, opacity = 0.7, group = "Raster 1")|>
  addLegend(pal = pal1, values = values(r1), title = "Raster 1", group = "Raster 1")|>
  
  # Add the second raster layer
  addRasterImage(r2, color = pal2, opacity = 0.7, group = "Raster 2")|>
  addLegend(pal = pal2, values = values(r2), title = "Raster 2", group = "Raster 2")|>
  
  # Add the third raster layer
  addRasterImage(r3, color = pal3, opacity = 0.7, group = "Raster 3")|>
  addLegend(pal = pal3, values = values(r3), title = "Raster 3", group = "Raster 3")|>
  
  # Add the fourth raster layer
  addRasterImage(r4, color = pal4, opacity = 0.7, group = "Raster 4")|>
  addLegend(pal = pal4, values = values(r4), title = "Raster 4", group = "Raster 4")|>
  
  # Add layer control to toggle raster visibility
  addLayersControl(
    overlayGroups = c("Raster 1", "Raster 2", "Raster 3", "Raster 4"),
    options = layersControlOptions(collapsed = FALSE)
  )
  

