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

# check to see if any grids are missing 
d10 <- paste0("data/processed/harmonizedImages/gridsWithCellCounts_",2010,".csv") |> read_csv()
d16 <- paste0("data/processed/harmonizedImages/gridsWithCellCounts_",2016,".csv") |> read_csv()
d20 <- paste0("data/processed/harmonizedImages/gridsWithCellCounts_",2020,".csv") |> read_csv()

# need to adjust to select for specific years 
for(year in c(2010,2016,2020)){
  # storage df 
  # df <- refCSV |>
  #   dplyr::mutate(
  #     ref_combined_map = NA,
  #     ref_harmonized_map_b = NA,
  #     ref_harmonized_map = NA,
  #     self_combined_map = NA,
  #     self_harmonized_map_b = NA,
  #     self_harmonized_map = NA,
  #     year = year
  #   )
  img <- images[grepl(pattern = year, x = images)]
  # check to see if new images are require 
  existingData <- paste0("data/processed/harmonizedImages/gridsWithCellCounts_",year,".csv") |>
    read_csv() |>
    dplyr::select("gridsToRework","ref_combined_map","ref_harmonized_map_b",
                  "ref_harmonized_map","self_combined_map", "self_harmonized_map_b",
                  "self_harmonized_map","year" )

  missedGrids <- grids[!grids %in% existingData$gridsToRework]
  # create new DF to bind 
  if(length(missedGrids)>0){
    df2 <- data.frame("gridsToRework"  = missedGrids,
                      "ref_combined_map"= NA,
                      "ref_harmonized_map_b" = NA,
                      "ref_harmonized_map"  = NA,
                      "self_combined_map" = NA,
                      "self_harmonized_map_b" = NA,
                      "self_harmonized_map" = NA,
                      "year" =NA )
    df <- bind_rows(existingData, df2)
  }else{
    df <- existingData
  }

  
  for(g in 1:nrow(df)){
    grid <- df$gridsToRework[g]
    print(grid)
    r2 <- img[grepl(pattern = paste0(grid,"_using"), x = img)] 
    if(length(r2)>0){
      #check for existing data 
      val <- unlist(df[g, 2:7] )
      if(TRUE %in% is.na(val)){
        print("gather data")
        for(i in names){
          print(i)
          select <- grepl(pattern = paste0(i,"_",grid), x = r2)
          if(TRUE %in% select){
            # read in image 
            r3 <- NA
            r3 <- try(rast(r2[select]))
            if(class(r3)== "SpatRaster"){
              # get pixel count 
              count <- freq(r3)
              # assign value to dataframe 
              df[df$gridsToRework == grid, i] <- count$count[2]
            }else{
              df[df$gridsToRework == grid, i] <- -1
            }
            
          }
        } 
      }else{
        print("data exists")
      }
    }
    write_csv(x = df, file = paste0("data/processed/harmonizedImages/gridsWithCellCounts_",year,".csv"))
  }
}


# Selecting the top two models for combined metric  -----------------------
gridCounts <- list.files(path = "data/processed/harmonizedImages",
                         pattern = "gridsWithCell",
                         full.names = TRUE)

for(i in seq_along(gridCounts)){
  # filter to specific year and select columns of interest 
  g <- read_csv(gridCounts[i]) |>
    filter(!is.na(ref_harmonized_map))|>
    select( "gridsToRework","ref_harmonized_map_b",  "ref_harmonized_map","self_harmonized_map_b","self_harmonized_map","year")|>
    dplyr::mutate(
      lowest = NA,
      second = NA
    )
  year <- g$year[1]
  g$year <- year
  for(j in 1:nrow(g)){
    # order the 
    vals <- g[j,2:5] |> 
      t() |>
      as.data.frame()|>
      dplyr::arrange(V1)
    # assign values to df 
    g[j,7] <- rownames(vals)[1]
    g[j,8] <- rownames(vals)[2]
  }
  write_csv(g, file = paste0("data/processed/harmonizedImages/topModels_",year,".csv"))
}


# used the top grids to generate a combined image  ------------------------
topGrids <- list.files(path = "data/processed/harmonizedImages",
                         pattern = "topModels_",
                         full.names = TRUE) |> 
  read_csv()
# quick summary 
lowest_counts <- topGrids|>
  count(lowest)|>
  arrange(desc(n))

# Count occurrences in the 'second' column
second_counts <- topGrids|>
  count(second)|>
  arrange(desc(n))


write_csv(x = topGrids, file = "data/processed/combinedHaromized/topModelsPerGrid.csv")
# list of all images 
images <- list.files(
  path = "data/processed/harmonizedImages",
  pattern = ".tif",
  full.names = TRUE
)


# loop over each features 
for(i in 1:length(topGrids$gridsToRework)){
  print(i)
  sel <- topGrids[i,]
  grid <- sel$gridsToRework
  year <- sel$year
  first <- sel$lowest
  second <- sel$second
  exportPath <- paste0("data/processed/combinedHaromized/",grid,"_",year,".tif")
  if(!file.exists(exportPath)){
    # gather paths 
    g1 <- images[grepl(pattern = paste0(grid,"_using"),x = images)]
    g2 <- g1[grepl(pattern = year, g1)]
    firstR <- g2[grepl(pattern = first, g2)] |> 
      rast() |>
      terra::subst(0, NA)
    secondR <- g2[grepl(pattern = second, g2)] |>
      rast()|>
      terra::subst(0, NA)
    # combine 
    combined <- firstR + secondR
    # export 
    terra::writeRaster(x = combined, filename = exportPath)
  }
}


