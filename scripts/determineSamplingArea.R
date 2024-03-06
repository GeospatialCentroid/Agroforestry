pacman::p_load(purrr,dplyr,sf,leaflet)

# main grid
grid <- sf::st_read("data/processed/griddedFeatures/twelve_mi_grid_uid.gpkg")

# neighborhood grids 
n_grids <- list.files(
  path = "data/processed",
  pattern = "neighborGrids.csv",
  full.names = TRUE,
  recursive = TRUE
  )|>
  purrr::map(read.csv)|>
  dplyr::bind_rows()

# unique id  
uniqueGrids <- unique(n_grids$Unique_ID)

grid_map <- grid |>
  dplyr::mutate(
    inModelArea = case_when(
      Unique_ID %in% uniqueGrids ~ 1,
      TRUE ~ 0
    ),
    popup = paste0(
      "ID:", Unique_ID,
      "<br>",
      "In Current Coveage: ", inModelArea)
  )


bins <- c(0,1)
pal <- colorFactor(c("red","green"), domain = grid_map$inModelArea)

# generate the map 
leaflet()|>
  addTiles()|>
  addPolygons(
    data = grid_map,
    fillColor = ~pal(inModelArea),
    weight = 2,
    opacity = 1,
    color = "white",
    popup = ~popup
    )
  
  