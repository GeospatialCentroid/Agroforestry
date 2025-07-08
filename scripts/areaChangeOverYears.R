# loading packages
pacman::p_load(terra, dplyr, tidyr, purrr, furrr, tictoc)

# for a COT file 
## determine the total area gained and lost between 10-16 and 16-20 
cotFiles <- list.files(path = "data/products/changeOverTime",
                       pattern = "_2.tif",
                       full.names = TRUE )
path <- cotFiles[10]

# r1 <- terra::rast(path)

calcAreaChanges <- function(path){
  # get grid id 
  vals <- stringr::str_split(path, pattern = "/") |> unlist()
  gID <- stringr::str_split(vals[4], pattern = "_") |> unlist()
  
  r1 <- terra::rast(path)$ChangeOverTime
  # grab total cells 
  totalCells <- terra::ncell(r1)
  
  df <- terra::freq(r1) |>
    dplyr::mutate(gridID = gID[1])|>
    dplyr::select(gridID, value,count) 
  # seperating here for conditional statment on the totalTOF cells calculations 
  df <- df |>
    tidyr::pivot_wider(names_from = value, values_from = count) |>
    rowwise()|> # Treat each row as a separate group for calculations
    mutate(allCells = totalCells,
           tofCells = sum(c_across(3:ncol(df)), na.rm = TRUE))|>
    ungroup() # Remove rowwise grouping after calculation
  rm(r1)
  # 0 : no trees 
  # 1 : trees loss from 2010
  # 3 : trees gained in 16 
  # 4 : trees loss in 20
  # 5 : trees gained in 20 
  # 6 : tree present in 10 and 20 
  # 8 : tree gained in 16 
  # 9 : consistent trees 
  return(df)
  print(gc(verbose = FALSE))
}

# tic()
# vals <- calcAreaChanges(path)
# toc()
# 13.784 sec elapsed ~4gb
# 
# tic()
# vals <- purrr::map(.x = cotFiles[1:10], .f = calcAreaChanges)
# toc()
# # 98.954 sec elapsed ~ unclear memory 

plan(strategy = multicore, workers = 5)
tic()
vals <- furrr::future_map(.x = cotFiles, .f = calcAreaChanges)
toc()
# 30 sec elapsed 5 workers ~ unclear memory 

# 
results <- dplyr::bind_rows(vals)
names(results) <- c("gridID", "No Trees", "Loss 2016", "Gain 2016", "Loss 2020",
                    "Gain 2020", "Loss 16 Gain 20", "Gain 16", "All Tree", 
                    "Total Cells", "Total TOF cells")
print(results)
write.csv(x = results, file = "data/products/areaMeasures/allGrids_06_2025.csv")
