library(tmap)
library(sf)
tmap_mode("view")


t2 <- st_read("C:/Users/dune/Desktop/Agroforestry/data/processed/griddedFeatures/twelve_mi_grid_uid.gpkg")


### so I'll need this to expand. 

selectedGrid <- "X12-601"

g1 <- t2[t2$Unique_ID == selectedGrid,]

g3 <- st_intersects(t2,g1, sparse = FALSE)

t3 <- t2[g3[,1],]


## disolve boundaries of the new area and use that to test intersection. This get the next layer. Could probably do a buffer id I know size of boxes  
g4 <- st_intersects(t2,t3, sparse = FALSE)

