### temp doc for developing the work flow 
pacman::p_load(dplyr,terra,sf, readr, stringr, tidyr, tmap, glcm, raster, furrr,
               tictoc, randomForest,caret)
tmap_mode("view")


data <- list.files("data/testFeatures", all.files = TRUE, full.names = TRUE,recursive = TRUE)

n1 <- rast(data[1]) |> 
  terra::project("epsg:4326")

names(n1) <- c("r", "g","b","n")


# Source functions  -------------------------------------------------------

source("testing/generateIndicies.R")
source("testing/aggregateImagery.R")

print("temp")

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

p2 <- sf::st_as_sf(x =p1,  coords = c("x","y"), dim = "XY")|> 
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


# set furrr processing environment  ---------------------------------------
plan(multisession, workers = 3)


# generate high resolution features  --------------------------------------
## might want to apply map outside of the runstion
tic()
r1 <- purrr::map(.x = c(2,3,4) ,.f = ag, raster = n1)
toc()

# tic()
# r1f <-  c(2,3,4) |> furrr::future_map(.f = ag, raster = n1)
# toc()

# generate indices ------------------------------------------------------
## we will probably have a selected resolution to use at this point so we might
## might not need the map function at all. 
r2 <- r1[[3]] # larger area
ndvi <- createNDVI(raster = r2)
# ndvi <- purrr::map(.x = r1, .f = createNDVI , .progress = TRUE)


# generate a multiband feature  -------------------------------------------
r2 <- c(r2, ndvi)


# generate GLMC on the high res features  ---------------------------------
# covert multiband terra object to a list of rasters
l1 <- list()

for(i in 1:nlyr(r2)){
  l1[[i]] <- raster(r2[[i]])
}

d2 <- createGLCM(band = l1[[2]],name = "green")

## again, not sure if we want to apply this to all bands or only the green band
## for now keep to a single and adjust if needed. 
# plan(multisession, workers = 5)
# tic()
# d2 <- furrr::future_map(.x = l1, createGLCM, .progress = TRUE, name =  )
# toc()
# convert back to 
# d3 <- map(d2, rast) |> rast() # furr process 
d3 <- rast(d2)
d4 <- c(r2, d3)


# extract values  ---------------------------------------------------------
values <- terra::extract(x = d4, y = vect(points))|>
  mutate(presence = as.factor(points$presence))|>
  dplyr::select(-ID)



# random forest model -----------------------------------------------------
## drop any NA values
dat <- values |>
  tidyr::drop_na() |>
  dplyr::select("r_4","g_4","b_4","n_4","n_4_NDVI","green_glcm_entropy",
                "green_glcm_second_moment",presence) # issue with "green_glcm_correlation" 
  # it does have a NA value, but droping that row doesn't seem to resolve the issue, droping the 

# call rf function 
rfm <- randomForest(formula=presence~., data=dat)
# apply function to the imagery
tic()
rp0 <- terra::predict(d4, rfm, na.rm=TRUE)
toc() ## 56 seconds 
# try the parallel 
tic()
rp1 <- predict(d4, rfm, cores=8, cpkgs="randomForest")
toc()
