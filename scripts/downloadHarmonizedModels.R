###
# pull the new modelled outputs from the gdrive 
#
### 

pacman::p_load(googledrive, terra, dplyr)
# establish connection
# drive_auth()

# this is the top level folder 
folder_id <- "https://drive.google.com/drive/u/0/folders/1QP6xpwwQSP1paTnsxjdWThy1qFqfuXvg" # url to the folder
drive_folder <- drive_get(id = folder_id)

folder_contents <- drive_ls(drive_folder) # just the high level folder handing the recursive elements in the loop 

# split into specific features 
for(i in 1:nrow(folder_contents)){
  d1 <- folder_contents[i,]
  files <- drive_ls(d1$id)
  # filter out .xml files 
  files <- files[grepl("\\.tif$", files$name), ]
  # download the specific files 
  for(j in 1:nrow(files)){
    feature <- files[j,]
    exportPath <- paste0("data/processed/harmonizedImages/",feature$name)
    if(!file.exists(exportPath)){
      drive_download(
        file = feature$id,
        path = exportPath,
        type = NULL,
        overwrite = FALSE,
      )
    }
  }
}

# need to get a list of 2010 features to regenerate 
images <- list.files("data/processed/harmonizedImages",
                     full.names = TRUE)

# drop all xml features 
tifs <- images[grepl("\\.tif$", images)]
# xml 
xml <- images[grepl("\\.xml$", images)]
lapply(X = xml, FUN = file.remove)

library(stringr)
basenames <- basename(tifs) |>
  stringr::str_split( pattern = "_")


gridID4 <- lapply(basenames, function(feature) {
  if (length(feature) >= 4) {
    return(feature[[4]])
  } else {
    return(NA) # Or some other indicator if the feature doesn't have 6 elements
  }
}) |> unlist()|> unique()
gridID5 <- lapply(basenames, function(feature) {
  if (length(feature) >= 5) {
    return(feature[[5]])
  } else {
    return(NA) # Or some other indicator if the feature doesn't have 6 elements
  }
}) |> unlist() |> unique()

# second method for selection locations 
vals <- unique(basenames |> unlist())
vals <- vals[!vals %in% c("b","using", "ref", "combined", "map", "2020.tif", "2016.tif", "2010.tif",
                          "harmonized", "self")]

# combine and select unique combinations 
l1 <- c(gridID4, gridID5)|> unique()
l1 <- l1[!l1 %in% c("b","using")]

df <- data.frame(gridsToRework = vals)
write.csv(df, file = "data/processed/harmonizedImages/gridsToRework.csv" )
df <- read.csv("data/processed/harmonizedImages/gridsToRework.csv")

