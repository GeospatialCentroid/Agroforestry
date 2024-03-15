pacman::p_load(purrr,dplyr,sf,leaflet)

# main grid
grid <- sf::st_read("data/processed/griddedFeatures/twelve_mi_grid_uid.gpkg")

# select from the n_grid that features that have been actively exported. 
exports <- c("X12-150","X12-207","X12-281","X12-300","X12-307","X12-32","X12-356"
             ,"X12-183","X12-318")

# neighborhood grids 
n_grids <- list.files(
  path = "data/processed",
  pattern = "neighborGrids.csv",
  full.names = TRUE,
  recursive = TRUE
  )
vals <- c()
# subset to the existing modeled features 
for(i in seq_along(exports)){
  vals[i] <- grep(pattern = exports[i], x = n_grids)
}

n_gridsSelect <- n_grids[vals] |> 
  purrr::map(read.csv)|>
  dplyr::bind_rows()

# unique id  
uniqueGrids <- unique(n_grids$Unique_ID)
# or for subset 
uniqueGrids <- unique(n_gridsSelect$Unique_ID)


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

leaflet()|>
  addTiles()|>
  addPolygons(
    data = n_grids,
    weight = 2,
    opacity = 1,
    color = "white",
    popup = ~popup
  )


### need to sample 
c("X12-519",
  "X12-115",
  "X12-99",
  "X12-83",
  "X12-91",
  "X12-131", 
  "X12-361", 
  "X12-388", 
  "X12-615", 
  "X12-624", 
  "X12-633", 
  "X12-642", 
  "X12-602")

  