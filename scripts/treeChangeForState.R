

pacman::p_load(reader, dplyr, sf, purrr)

grids2016 <- sf::st_read("data/products/modelGrids_2016.gpkg") |>  assignScore() |> dplyr::mutate(year= "2016")


# read in all carbon measures and appending them to the grid layer 
files <- list.files(path = "data/products/carbonMeasures",
                    pattern = "_1016.csv",
                    recursive = TRUE,
                    full.names = TRUE)

t1 <- files |>
  purrr::map(read_csv)

# gather all ids 
ids <- grids2016$Unique_ID

# testing 
id <- ids[1]
grid <- grids2016
grid$carbonChange <- NA

# assign area 
assignVal <- function(id, grid){
  # grab csv 
  d1 <- files[grepl(pattern = paste0(id,"_"),x = files)] |> read_csv()
  if(nrow(d1) > 0){
    grid[grid$Unique_ID == id, "carbonChange"] <- d1[d1$type=="all", "totalCarbonChange"]
  }
  return(grid)
}

for(i in seq_along(ids)){
  id <- ids[i]
  print(i)
  grid <- assignVal(id = id, grid = grid)
}

# export
sf::st_write(obj = grid, dsn = "data/products/carbonMeasures/carbonChange2010-2016.gpkg")
