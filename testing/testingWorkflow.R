### temp doc for developing the work flow 

pacman::p_load(dplyr,terra,sf, readr, stringr, tidyr, tmap, glcm, raster, furrr)
tmap_mode("view")

data <- list.files("data/testFeatures", all.files = TRUE, full.names = TRUE,recursive = TRUE)

n1 <- rast(data[1]) |> 
  terra::project("epsg:4326")

names(n1) <- c("r", "g","b","n")



# silly stuff to prep the test input data ---------------------------------
p1 <- read_csv(data[4]) |> 
  dplyr::select(WKT) |>
  pull() |>
  str_remove_all("POINT ")|>
  str_remove_all("[()]") |> 
  str_replace_all(pattern = " ", replacement = ", ") |> 
  data.frame()

names(p1) <- "vals"

p1 <- p1 |>
  tidyr::separate( col = "vals", sep = ", ", into = c("x", "y"))|>
  mutate(x = as.numeric(x),
         y = as.numeric(y))

p2 <- sf:: st_as_sf(x = p1, coords = c("x","y"), dim = "XY",) |> 
  mutate(presence = 1)
st_crs(p2)= 4326

qtm(p2)

a1 <- read_csv(data[3])|> 
  dplyr::select(WKT) |>
  pull() |>
  str_remove_all("POINT ")|>
  str_remove_all("[()]") |> 
  str_replace_all(pattern = " ", replacement = ", ") |> 
  data.frame()
names(a1) <- "vals"

a1 <- a1 |>
  tidyr::separate( col = "vals", sep = ", ", into = c("x", "y"))|>
  mutate(x = as.numeric(x),
         y = as.numeric(y))

a2 <- sf:: st_as_sf(x = a1, coords = c("x","y"), dim = "XY") |> 
  mutate(presence = 0)
st_crs(a2)= 4326

qtm(a2)

points <- bind_rows(p2,a2)



# generate indices -------------------------------------------------------

createNDVI <- function(raster){
  # (NIR - R) / (NIR + R)
  r1 <- (raster$n - raster$r) / (raster$n + raster$r)
}
# slow so for now only running on the green band
## test at smaller areas to figure out a realistic run time 
createGLCM <- function(band){
  name <- names(band)
  vals <- glcm(band,
               window = c(3, 3),
               statistics = 
                 c("entropy", 
                   "second_moment",
                   "correlation")
               )
  names(vals) <- paste0(name,"_", names(vals))
  return(vals)
}


ndvi <- createNDVI(n1)
names(ndvi) <- "ndvi"
# generate a multiband feature  -------------------------------------------
n2 <- c(n1, ndvi)
# original data is ~0.5 meters
111139 * res(n2)

# extract values ----------------------------------------------------------
v2 <- terra::extract(x = n2, y = points)


# resample raster data to high resultions  --------------------------------

# factor of work is working 1 cell in all direction so the avergage of 9 cells
# works in parallel which I'd like to use if possilbe.
n2_3 <- terra::aggregate(x = n2, fact = 3, fun = "mean") # cell 1.5 meter
111139 * res(n2_3)

n2_3_3 <-terra::aggregate(x = n2, fact = 6, fun = "mean") # cell 3 meter
111139 * res(n2_3_3)



# generate GLMC on the high res features  ---------------------------------
l1 <- list()

for(i in 1:nlyr(n2_3_3)){
  l1[[i]] <- raster(n2_3_3[[i]])
}

library(tictoc)
tic()
ndvi1 <- createGLCM(band = raster(n2_3_3$n))
toc()

plan(multisession, workers = 5)
tic()
d2 <- furrr::future_map(.x = l1, createGLCM )
toc()

# convert back to 
d3 <- map(d2, rast) |> rast() 
d4 <- c(n2_3_3, d3)

