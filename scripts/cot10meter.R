pacman::p_load(purrr, terra, tictoc)

# generate the cot files
rastPaths <- list.files("data/products/tenMeterModels", full.names = TRUE)
# select grid ids
grids <- paste0("X12-", 1:773)

# cot function
genCOT_10m <- function(gridID, rastPaths) {
  message("Working on gridID: ", gridID)
  # define export location
  exportPath <- paste0(
    "data/products/cot_10meter/COT_10m_",
    gridID,
    ".tif"
  )
  if (!file.exists(exportPath)) {
    # pull in three images
    images <- rastPaths[grepl(pattern = paste0(gridID, "_"), x = rastPaths)]
    # parse to years
    # reclass images images by year
    r10 <- images[grepl(pattern = "_2010", images)] |>
      terra::vrt()
    names(r10) <- "r10"
    r16 <- images[grepl(pattern = "_2016", images)] |>
      terra::vrt() |>
      terra::subst(from = 1, to = 3)
    names(r16) <- "r16"
    r20 <- images[grepl(pattern = "_2020", images)] |>
      terra::vrt() |>
      terra::subst(from = 1, to = 5)
    names(r20) <- "r20"
    rasters <- list(r10 = r10, r16 = r16, r20 = r20)
    # store as list for processing steps
    # calculate the ncell to test for difference in extent
    areas <- sapply(rasters, ncell)

    # Find the name/index of the smallest one
    smallest_idx <- which.min(areas)
    template_raster <- rasters[[smallest_idx]]
    aligned_rasters <- lapply(rasters, function(x) {
      # If it's already the template, return as is to save processing time
      if (compareGeom(x, template_raster, stopOnError = FALSE)) {
        return(x)
      } else {
        return(terra::resample(x, template_raster, method = "near"))
      }
    })
    # cot features
    cot <- terra::rast(aligned_rasters) |>
      sum(na.rm = TRUE)
    # export
    terra::writeRaster(
      x = cot,
      filename = exportPath,
      overwrite = TRUE
    )
  }
}

# 1.137 sec elapsed
# tic()
# genCOT_10m(gridID = "X12-150", rastPaths = rastPaths)
# toc()

# 8 seconds
tic()
purrr::walk(.x = grids, .f = genCOT_10m, rastPaths = rastPaths)
toc()


# test function to check outputs
check_random_cot_outputs <- function(dir_path = "data/products/cot_10meter") {
  # List files
  all_files <- list.files(dir_path, pattern = "\\.tif$", full.names = TRUE)
  if (length(all_files) == 0) {
    stop("No .tif files found in ", dir_path)
  }
  # Select 5 random files
  selected_files <- sample(all_files, min(5, length(all_files)))
  message(
    "Selected files for inspection:\n",
    paste(basename(selected_files), collapse = "\n")
  )
  # Plot them individually
  for (f in selected_files) {
    r <- rast(f)
    # Plot
    plot(
      r,
      main = basename(f)
    )
  }
}
# Run the check
check_random_cot_outputs()
