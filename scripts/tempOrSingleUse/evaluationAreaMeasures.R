pacman::p_load(terra, dplyr,purrr, furrr, stringr)

#test of the vectorization method 

## read in file 
## convert to polygons 
## disaggregate the polygons to individuals features 
## assign area for each features 
## convert to data frame 
## group by and values per year 


# test the time of the rast to vect conversion 
path <- "data/products/changeOverTime/X12-766_changeOverTime_2.tif"
vals <- stringr::str_split(path, pattern = "/") |> unlist()
gID <- stringr::str_split(vals[4], pattern = "_") |> unlist()
areaCounts <- function(path){
  # get grid id 
  vals <- stringr::str_split(path, pattern = "/") |> unlist()
  vals2 <- stringr::str_split(vals[4], pattern = "_") |> unlist()
  gID <- vals2[1]
  print(gID)
  ## read in file 
  f1 <- terra::rast(path)["ChangeOverTime"]
  ## get grid ID 
  
  ## convert to polygons
  ## disaggregate the polygons to individuals features 
  v1 <-  as.polygons(f1, values=TRUE) |> terra::disagg()
  ## assign area for each features 
  v1$area <- terra::expanse(v1, unit="m")
  ## convert to data frame 
  df <- as.data.frame(v1) |>
    dplyr::filter(ChangeOverTime !=0 )
  ## group by and values per year 
  df2 <- df |>
    dplyr::mutate(
      y10 = case_when(
        ChangeOverTime %in% c(1,4,6,9) ~ TRUE
      ),
      y16 = case_when(
        ChangeOverTime %in% c(3,4,8,9) ~ TRUE
      ),
      y20 = case_when(
        ChangeOverTime %in% c(5,6,8,9) ~ TRUE
      ),
    )
  ## calculate mean and std areas pre year 
  d10 <- df2 |>
    dplyr::group_by(y10)|>
    dplyr::summarise(
      count = n(),
      totalArea = sum(area, na.rm = TRUE),
      meanArea = mean(area, na.rm = TRUE),
      sdArea = sd(area, na.rm = TRUE),
    )|>
    dplyr::mutate(year = "2010") |>
    dplyr::filter(!is.na(y10)) |>
    dplyr::select(year, totalArea, count, meanArea, sdArea)
  d16 <- df2 |>
    dplyr::group_by(y16)|>
    dplyr::summarise(
      count = n(),
      totalArea = sum(area, na.rm = TRUE),
      meanArea = mean(area, na.rm = TRUE),
      sdArea = sd(area, na.rm = TRUE),
    ) |>
    dplyr::mutate(year = "2016") |>
    dplyr::filter(!is.na(y16)) |>
    dplyr::select(year, totalArea, count, meanArea, sdArea)
  d20 <- df2 |>
    dplyr::group_by(y20)|>
    dplyr::summarise(
      count = n(),
      totalArea = sum(area, na.rm = TRUE),
      meanArea = mean(area, na.rm = TRUE),
      sdArea = sd(area, na.rm = TRUE),
    ) |>
    dplyr::mutate(year = "2020") |>
    dplyr::filter(!is.na(y20)) |>
    dplyr::select(year, totalArea, count, meanArea, sdArea)
  #bind data 
  output <- bind_rows(d10,d16,d20)
  output$grid <- gID
  return(output)
}


files <- list.files(path = "data/products/changeOverTime",
                    pattern = "_2.tif",
                    full.names = TRUE)

# test time 
## 163 seconds ~ 10G 
# tic()
# areaCounts(path = files[10])
# toc()
# 
# # sequential 
# tic()
# p1 <- purrr::map(.x = files[1:10], .f = areaCounts)
# toc()

plan(multicore, workers = 5)
p2 <- furrr::future_map(.x = files, .f = areaCounts)

allData <- bind_rows(p2) 
print(allData)
# export 
write.csv(allData, "data/temp/averageAreaCounts.csv")

