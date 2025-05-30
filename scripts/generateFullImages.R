
pacman::p_load(terra,dplyr,sf, furrr)

modelGrids <- sf::st_read("data/processed/griddedFeatures/twelve_mi_grid_uid.gpkg")


year <- 2020

models <- list.files(paste0("data/products/models",year,"/fullImages"),
                     full.names = TRUE)
grids <- list.files(paste0("data/products/models",year,"/grids"),
             full.names = TRUE)
ids <- modelGrids$Unique_ID

generateFullImages <- function(i, year, models, grids){
  # test for presence 
  m1 <- models[grepl(pattern = paste0(i,"_full"), models)]
  exportName <- paste0("data/products/models",year,"/fullImages/",i,"_fullUnMasked.tif")
  if(length(m1) == 0){
    print(i)
    g1 <- grids[grepl(pattern = paste0(i,"_"), grids)]
    print(length(g1))
    if(length(g1)==1){
      r1 <- terra::rast(g1)
      terra::writeRaster(r1, exportName)
      rm(r1)
    }
    if(length(g1)==2){
      # two options, merge or add 
      ## if _b_ is in a file name add 
      ## else merge 
      if(TRUE %in% grepl(pattern = "_b_", x = g1)){
        print("combine")
        r1 <- terra::rast(g1[1])
        r2 <- terra::rast(g1[2])
        r3 <- r1 + r2
        r3 <- terra::subst(r3, from =1 ,to =0 )
        r3 <- terra::subst(r3, from =2 ,to =1 )
        terra::writeRaster(r3, exportName)
        rm(r1)
        rm(r2)
        rm(r3)
        
      }else{
        print("merge")
        r1 <- terra::rast(g1[1])
        r2 <- terra::rast(g1[2])
        r3 <- terra::merge(r1,r2)
        terra::writeRaster(r3, exportName)
        rm(r1)
        rm(r2)
        rm(r3)
      }
    }
    if(length(g1)==4){
      # split out the b and a models 
      b1 <- g1[grepl("_b_", g1)]
      a1 <- g1[!grepl("_b_", g1)]
      # merge the sets 
      r1 <- terra::merge(rast(b1[1]), rast(b1[2]))
      r2 <- terra::merge(rast(a1[1]), rast(a1[2]))
      r3 <- r1 + r2
      r3 <- terra::subst(r3, from =1 ,to =0 )
      r3 <- terra::subst(r3, from =2 ,to =1 )
      terra::writeRaster(r3, exportName)
      rm(r1)
      rm(r2)
      rm(r3)
    }
  }
  gc()
}


for(i in ids){
  print(i)
  generateFullImages(i = ids, year = year, models = models, grids = grids)
}

plan(strategy = "multicore", workers = 4)
furrr::future_map(.x =ids, .f = generateFullImages,
                  year = 2020,
                  models = models,
                  grids = grids)

