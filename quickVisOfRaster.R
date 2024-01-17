

library(terra)
library(leaflet)

r1 <- terra::rast("C:/Users/dune/Downloads/testExport_01169.tif")

pal <- colorNumeric(c("white","green"), values(r1),
                    na.color = "transparent")

leaflet()|>
  leaflet::addProviderTiles(providers$Esri.WorldImagery)|>
  leaflet::addRasterImage(r1,
                          colors = pal,
                          opacity = 0.8,
                          group = "classification")|>
  addLayersControl(
    overlayGroups = c("classification"),
    options = layersControlOptions(collapsed = FALSE)
  )
