####
# look at the harmonized models and determine the number of TOF
# Use this to select the two options that have the lowest amount 
# 

pacman::p_load(readr, dplyr, terra)

# read in all features ----------------------------------------------------
refCSV <- read_csv("data/processed/harmonizedImages/gridsToRework.csv")
# images 
images <- list.files(path = "data/processed/harmonizedImages",
                     pattern = ".tif",
                     full.names = TRUE)
# storage df 
df <- refCSV |>
  dplyr::mutate(
    ref_combined_map = NA,
    ref_harmonized_map_b = NA,
    ref_harmonized_map = NA,
    self_combined_map = NA,
    self_harmonized_map_b = NA,
    self_harmonized_map = NA
  )
# expected names
names <- c("ref_combined_map" ,
           "ref_harmonized_map_b" ,
           "ref_harmonized_map" ,
           "self_combined_map" ,
           "self_harmonized_map_b" ,
           "self_harmonized_map" )


# loop over the images and record the area measures for all featur --------
grids <- refCSV$gridsToRework

for(grid in grids[1]){
  print(grid)
  r1 <- images[grepl(pattern = paste0(grid,"_using"), x = images)]
  for(i in names){
    print(i)
    select <- grepl(pattern = paste0(i,"_",grid), x = r1)
    if(TRUE %in% select){
      # read in image 
      r2 <- rast(r1[select])
      # get pixel count 
      count <- freq(r2)
      # assign value to dataframe 
      df[df$gridsToRework == grid, i] <- count$count[2]
    }
  }
}

