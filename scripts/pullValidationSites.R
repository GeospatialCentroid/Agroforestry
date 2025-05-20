pacman::p_load(dplyr,terra)


# load subgrid 
subG <- terra::vect("data/products/two_sq_grid.gpkg")
tenG <- terra::vect("data/products/modelGrids_2010.gpkg")
tenG16 <- terra::vect("data/products/modelGrids_2016.gpkg")
tenG20 <- terra::vect("data/products/modelGrids_2020.gpkg")


# 2010
modelGrids <-c("X12-115","X12-115","X12-131","X12-150","X12-183","X12-183",
             "X12-207","X12-278","X12-281","X12-300","X12-300","X12-307",
             "X12-307","X12-318","X12-318","X12-32","X12-356","X12-361",
             "X12-388","X12-388","X12-440","X12-519","X12-594","X12-602",
             "X12-602","X12-615","X12-624","X12-642","X12-677","X12-83",
             "X12-91","X12-99")
subGrids <-c("1200","1200","2572","12963","12000","12000","4330","19547",
             "14758","13638","13659","11577","11577","12877","12877","1473",
             "22744","19763","10880","10880","23005","28032","27935",
             "16513","16513","27785","29389","23457","25518",
             "402","2233","7729"
)
# datatable
dt <- data.frame(modelGrid = modelGrids, subGrid = subGrids )
dt$year <- 2010
dt$totalCells <- NA
dt$treeCells<- NA
dt$maskedCells<- NA


# 2016
modelGrids <-c("X12-115","X12-131","X12-131","X12-150","X12-150","X12-183",
               "X12-183","X12-278","X12-278","X12-300","X12-300","X12-307",
               "X12-318","X12-318","X12-356","X12-356","X12-361","X12-361",
               "X12-388","X12-388","X12-519","X12-519","X12-594","X12-594",
               "X12-602","X12-602","X12-624","X12-624","X12-642","X12-642",
               "X12-661","X12-677","X12-677","X12-709","X12-83","X12-91",
               "X12-99","X12-99"
)
subGrids <-c("594","456","2572","12659","6603","11710","12000","18037","12004",
             "5822","13638","6165","8345","12877","12781","16121","11319",
             "19763","22986","10880","24110","28032","17395","24628","20451",
             "16513","30590","26650","27975","23457","30823","24297","25518",
             "30850","2828","1328","4121","7729"
)
# datatable
dt <- data.frame(modelGrid = modelGrids, subGrid = subGrids )
dt$year <- 2016
dt$totalCells <- NA
dt$treeCells<- NA
dt$maskedCells<- NA




# 2020
modelGrids <-c(
  "X12-115","X12-131","X12-131","X12-150","X12-183","X12-300","X12-307",
  "X12-318","X12-32","X12-356","X12-356","X12-361","X12-388","X12-440",
  "X12-519","X12-602","X12-602","X12-615","X12-615","X12-624","X12-633",
  "X12-642","X12-677","X12-709","X12-83","X12-91","X12-99"
)
subGrids <-c("1203","2572","6188","12632","12000","13638","5551","12877","8690",
             "9472","20332","19763","10880","23945","28032","16513","24675",
             "24161","26298","23950","27938","23457","25518","23306","5238",
             "1325","7729"
)
# datatable
dt <- data.frame(modelGrid = modelGrids, subGrid = subGrids )
dt$year <- 2020
dt$totalCells <- NA
dt$treeCells<- NA
dt$maskedCells<- NA










year <- "2020"
# pull measures 
for(i in 1:nrow(dt)){
  print(i)
  # pull sub grid 
  s1 <- subG[subG$FID_two_grid == dt$subGrid[i], ]
  # interest with 12m grid 
  if(year == 2010){
    s2 <- terra::intersect(x = tenG, y = centroids(s1))
  }
  if(year == 2016){
    s2 <- terra::intersect(x = tenG16, y = centroids(s1))
  }
  if(year == 2020){
    s2 <- terra::intersect(x = tenG20, y = centroids(s1))
  }
  
  
  p1 <- paste0("data/products/models",year)
  # pull original model 
  m1 <- list.files(path = p1,
                   pattern = paste0(s2$Unique_ID[1], "_fullUnMasked"),
                   recursive = TRUE,
                   full.names = TRUE) |> terra::rast()
  
  # pull masked model
  m2 <- list.files(path = p1,
                   pattern = paste0(s2$Unique_ID[1], "_Masked"),
                   recursive = TRUE,
                   full.names = TRUE) |> terra::rast()

  
  # crop 
  ## all trees
  m1Crop <- terra::crop(x = m1, y = s1)
  ## crops trees 
  m2Crop <- terra::crop(x = m2, y = s1)
  
  # generate pixel counts 
  treeVals <- terra::freq(m1Crop)
  
  cropVals <- terra::freq(m2Crop)
  
  # assign vals 
  dt$totalCells[i] <- sum(treeVals$count)
  dt$treeCells[i] <- treeVals$count[treeVals$value == 1]
  dt$maskedCells[i] <- dt$treeCells[i] - cropVals$count[cropVals$value == 1]
}
#2010
write.csv(x = dt, 
          file = "~/trueNAS/work/Agroforestry/data/processed/validationCounts/counts2010.csv")
#2016
write.csv(x = dt, 
          file = "~/trueNAS/work/Agroforestry/data/processed/validationCounts/counts2016.csv")

#2020
write.csv(x = dt, 
          file = "~/trueNAS/work/Agroforestry/data/processed/validationCounts/counts2020.csv")






