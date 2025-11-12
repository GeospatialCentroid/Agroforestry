pacman::p_load(reader, dplyr, sf, purrr, stringr, terra, furrr)

# grab all ids
grids2016 <- sf::st_read("data/products/modelGrids_2016.gpkg")
# ids
ids <- grids2016$Unique_ID
rm(grids2016)
# function to select he harmonized images over the non harmonized
prioritized_files <- function(file_paths) {
  tibble(path = file_paths) |>
    # Get just the filename to work with
    mutate(filename = basename(path)) |>
    # 1. Create a common 'base_id' by removing the suffixes
    # This removes either "_harmonized_Masked.tif" or just "_Masked.tif"
    mutate(base_id = str_remove(filename, "(_harmonized)?_Masked\\.tif$")) |>
    # 2. Create a priority flag (TRUE is better)
    mutate(is_harmonized = str_detect(filename, "_harmonized_")) |>
    # 3. Group by the common ID
    group_by(base_id) |>
    # 4. Sort each group so the harmonized (TRUE) file is first
    arrange(desc(is_harmonized)) |>
    # 5. Keep only the first row (the best one) from each group
    slice_head(n = 1) |>
    # Clean up
    ungroup() |>
    # 6. Get the original paths back
    pull(path)
}

# id <- ids[1]
# paths <- files
# year <- "2010"
aggregateAndExport <- function(id, paths, year, overwrite = FALSE) {
  # print statement
  message(paste("Working on: ID", id, "Year", year))
  # need 80% area for classificaiton
  # all values >= 0 and <= 0.8 become 0
  # all values >= 0.8 and <= 1 become 1
  m <- c(0, 0.8, 0, 0.8, 1, 1)
  rclmat <- matrix(m, ncol = 3, byrow = TRUE)

  # subset paths to year
  paths <- paths[grepl(pattern = year, x = paths)]

  # paths
  path <- paths[grepl(pattern = paste0(id, "_"), x = paths)]
  if (length(path) == 2) {
    path <- path[grepl(pattern = "_harmonized", x = path)]
  }
  if (length(path) > 0) {
    r1 <- rast(path)

    if (year == "2010") {
      file2010 <- paste0(
        "data/products/tenMeterModels/tenMeter_",
        id,
        "_2010.tif"
      )
      print(file2010)
      if (!file.exists(file2010) | overwrite == TRUE) {
        y10 <- r1 |>
          terra::aggregate(fact = 10) |>
          terra::classify(rclmat)
        terra::writeRaster(x = y10, filename = file2010, overwrite = TRUE)
      }
    }

    if (year == "2016") {
      file2016 <- paste0(
        "data/products/tenMeterModels/tenMeter_",
        id,
        "_2016.tif"
      )
      print(file2016)
      if (!file.exists(file2016) | overwrite == TRUE) {
        y16 <- r1 |>
          terra::aggregate(fact = 10) |>
          terra::classify(rclmat)
        terra::writeRaster(x = y16, filename = file2016, overwrite = TRUE)
      }
    }

    if (year == "2020") {
      file2020 <- paste0(
        "data/products/tenMeterModels/tenMeter_",
        id,
        "_2020.tif"
      )
      print(file2020)
      if (!file.exists(file2020) | overwrite == TRUE) {
        y20 <- r1 |>
          terra::aggregate(fact = 10) |>
          terra::classify(rclmat)
        terra::writeRaster(x = y20, filename = file2020, overwrite = TRUE)
      }
    }
  }
}

# read in all images per year and reorder the haromized images
tif10 <- prioritized_files(list.files(
  "data/products/models2010/",
  pattern = "_Masked.tif",
  recursive = TRUE,
  full.names = TRUE
))
tif16 <- prioritized_files(list.files(
  "data/products/models2016/",
  pattern = "_Masked.tif",
  recursive = TRUE,
  full.names = TRUE
))
tif20 <- prioritized_files(list.files(
  "data/products/models2020/",
  pattern = "_Masked.tif",
  recursive = TRUE,
  full.names = TRUE
))


# ids16 <- df |> dplyr::filter(year == 2016) |> dplyr::select(gridsToRework) |> pull()
# ids20 <- df |> dplyr::filter(year == 2020) |> dplyr::select(gridsToRework) |> pull()

# for (i in seq_along(ids)) {
#   id <- ids[i]
#   aggregateAndExport(id = id, paths = tif10, year = "2010", overwrite = TRUE)
#   aggregateAndExport(id = id, paths = tif16, year = "2016", overwrite = TRUE)
#   aggregateAndExport(id = id, paths = tif20, year = "2020", overwrite = TRUE)
# }
# ## furrr implementation
# Set up your parallel workers (e.g., all cores minus one)
plan(multisession, workers = 8)

# using walk because I'm not reutning and object
# 2010
furrr::future_walk(
  .x = ids,
  .f = aggregateAndExport,
  .progress = TRUE,
  paths = tif10,
  year = "2010",
  overwrite = TRUE
)
# 2016
furrr::future_walk(
  .x = ids,
  .f = aggregateAndExport,
  .progress = TRUE,
  paths = tif16,
  year = "2016",
  overwrite = TRUE
)
# 2020
furrr::future_walk(
  .x = ids,
  .f = aggregateAndExport,
  .progress = TRUE,
  paths = tif20,
  year = "2020",
  overwrite = TRUE
)
