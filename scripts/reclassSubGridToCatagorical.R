pacman::p_load(terra)


# list all images of interest 
images <- list.files(path = "data/products/subGridAreaEvaluations",
                     pattern = "_2016",
                     full.names = TRUE)

imagePath <- images[1]
cat_and_export <- function(imagePath){
  # grab image name 
  name <- basename(imagePath)
  name2 <- tools::file_path_sans_ext(basename(imagePath))
  r1 <- rast(imagePath)
  # # reclass to catagorical
  levels(r1) <- data.frame(id=0:1, ChangeOverTime=c("0", "1"))
  # export 
  writeRaster(x = r1, filename = paste0("data/products/testingSubGridFactors/factor_", name))
}

for(i in seq_along(images)){
  print(i)
  cat_and_export(imagePath = images[i])
}
