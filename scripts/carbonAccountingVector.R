pacman::p_load(terra,dplyr, sf, tictoc, tmap)
tmap::tmap_mode("view")

###
# second attempt at templating the itortion testing options 
# aiming to keep things as vectors rather then spatial objects 
####


# variables 
grid10 <- sf::st_read("data/products/modelGrids_2010.gpkg")
grid16 <- sf::st_read("data/products/modelGrids_2016.gpkg")
grid20 <- sf::st_read("data/products/modelGrids_2020.gpkg")
# unique model grids 
modelGrids <- unique(c(unique(grid10$modelGrid),
                       unique(grid16$modelGrid),
                       unique(grid20$modelGrid)))
# qtm(grid10)

# remove na 
modelGrids <- modelGrids[!is.na(modelGrids)]

# list change over time files 
cot <- list.files(path = "data/products/changeOverTime",
                  pattern = ".tif",
                  full.names = TRUE,
                  recursive = TRUE)
# grab features with correct riparian mask 
cot <- cot[grepl("_2", x = cot)]
###
#
# currently all cot images have a values of zero where masked areas should be 
#
###

# temp dataframe with vailation values 
validataion <-data.frame(
  modelGrid = c("X12-131", "X12-131", "X12-131"),
  gridID = c("X12-10", "X12-10","X12-10"),
  year = c(2010, 2016, 2020),
  truepositive = c(0.80, 0.90, 0.75),
  truenegative = c(0.12, 0.110, 0.125)
)


## we need to itorate over the gridID features 
gridIds <- unique(grid10$Unique_ID)


# testing 
gridID = "X12-10" # for validation indexing 
# gridID = "X12-225" # for NA mask testing 


test <- function(gridID, validataion,cot, grid10, grid16,grid20){
  
  # vector based method ----------------------------------------------------
  
  # used gridID and validation data to pull error measures per each year 
  # v1 <- validataion[validataion$gridID == gridID, ]
  # v10 <- v1[v1$year == "2010",]
  # v16 <- v1[v1$year == "2010",]
  # v20 <- v1[v1$year == "2010",]
  # # read in cot file 
  # r1 <- terra::rast(cot[grepl(pattern = paste0(gridID,"_change"), x = cot)])
  # # split out cot and riparian 
  # cot1 <- r1$ChangeOverTime 
  # # riparian <- r1$RiparianMask
  # rm(r1)
  # 

  # transform data to vector 
  # vals <- as.data.frame(terra::values(cot1))
  # # regenerate values for each year as a column in dataframe 
  # allVals <- vals |>
  #   dplyr::mutate(
  #     y10 = case_when(
  #       ChangeOverTime == 0 ~ 0,
  #       is.na(ChangeOverTime) ~ NA,
  #       ChangeOverTime %in% c(1, 4, 6, 9) ~ 1,
  #       TRUE ~ 0), 
  #     y16 = case_when(
  #       ChangeOverTime == 0 ~ 0,
  #       is.na(ChangeOverTime) ~ NA,
  #       ChangeOverTime %in% c(3, 4, 8, 9) ~ 1,
  #       TRUE ~ 0), 
  #     y20 = case_when(
  #       ChangeOverTime == 0 ~ 0,
  #       is.na(ChangeOverTime) ~ NA,
  #       ChangeOverTime %in% c(5, 6, 8, 9) ~ 1,
  #       TRUE ~ 0), 
  #   )
  # # might use the as.integer() call on these to reduce storage size 
  # 
  # # Drop the original data 
  # allVals <- allVals[,2:4]
  # size <- object.size(x = allVals)
  # print(size, units = "Gb")
  # # 2.8 gb to hold on vector of ~350 million values 
  # 
  # 
  # # ## testing reassignment 
  # # temp <- cot1 
  # # # assign values based on a vector 
  # # values(temp) <- allVals$y10
  # # # assign values based on the standard reclassification method 
  # # # 2010 only 
  # # m <- rbind(c(0, 0),
  # #            c(1, 1),
  # #            c(3, 0),
  # #            c(4, 1),
  # #            c(5, 0),
  # #            c(6, 1),
  # #            c(8, 0),
  # #            c(9, 1))
  # # r10 <- cot1 |> 
  # #   terra::classify(m, others=NA)
  # # 
  # # # compare results  
  # # diff <- temp - r10
  # # diff
  # 
  # ###
  # # this is reasonable place to end this function, just use the structure above to determine the vectors for three
  # # years 
  # ###
  # binaryVector <- allVals$y10
  # year <- 2010
  # 
  # probabilistic_flip <- function(binaryVector, validataion, year) {
  #   # select validation limits 
  #   truePos <- validataion[validataion$year == year, "truepositive"]
  #   trueNeg <- validataion[validataion$year == year, "truenegative"]
  #   # set seed 
  #   set.seed(1234)
  #   # Generate random numbers between 0 and 1
  #   random_numbers <- runif(length(binaryVector))
  #   
  #   # Create a new vector to store the flipped values
  #   flippedVector <- binaryVector
  #   
  #   # Flip 0 to 1
  #   flippedVector[binaryVector == 0 & random_numbers < trueNeg] <- 1
  #   
  #   # Flip 1 to 0
  #   flippedVector[binaryVector == 1 & random_numbers < truePos] <- 0
  #   
  #   return(flippedVector)
  # }
  # 
  # # test time on one flip 
  # tic()
  # f1 <- probabilistic_flip(binaryVector = binaryVector,
  #                          validataion = validataion,
  #                          year = year)
  # toc()
  # # 12.5 sec 
  
  # so a few things here. 
  # with each vector of values being ~ 3gb I don't think it's reasonable to do 100s itorations
  # could potential write out the vectors but that's 3tb of data for one site one year. We 
  # need 770 sites over three years. 
  
  # option 1  
  # I think it's reasonable to produce the average values across the 1000 iterations.
  # this could include some random elements to generate the carbon measures as well  
  # What we would save for the year is a average measure across all replicates 
  
  # option 2 
  # stick to working with the rast objects as they seem amazingly efficient in storing data 
  
  
  # used gridID and validation data to pull error measures per each year 
  v1 <- validataion[validataion$gridID == gridID, ]
  v10 <- v1[v1$year == "2010",]
  v16 <- v1[v1$year == "2010",]
  v20 <- v1[v1$year == "2010",]
  # read in cot file 
  r1 <- terra::rast(cot[grepl(pattern = paste0(gridID,"_change"), x = cot)])
  # split out cot and riparian 
  cot1 <- r1$ChangeOverTime 
  # riparian <- r1$RiparianMask
  # remove r1 
  rm(r1)
  
  
  
  rast <- cot1
  valLength <- nrow(terra::values(rast)) 
  year <- 2010
  probabilistic_flip_raster <- function(rast, validataion, year, valLength) {
    # select validation limits 
    truePos <- validataion[validataion$year == year, "truepositive"]
    trueNeg <- validataion[validataion$year == year, "truenegative"]
    # set seed 
    set.seed(1234)
    
    # Generate random numbers between 0 and 1
    random_numbers <- runif(valLength)
    
    # reclass raster
    ## this can become a function that takes in the year and rast. Should already have it. 
    if(year == 2010){
      m <- rbind(c(0, 0),
                 c(1, 1),
                 c(3, 0),
                 c(4, 1),
                 c(5, 0),
                 c(6, 1),
                 c(8, 0),
                 c(9, 1))
      rast <- rast |>
        terra::classify(m, others=NA)
    }
    # generate a 0 and 1 raster 
    rast0 <- terra::subst(rast, from = 1, to = NA)
    rast1 <- terra::subst(rast, from = 0, to = NA)
    # generate a random value rast
    rastRandom <- rast 
    values(rastRandom) <-  random_numbers
    
    # add and reclass 
    # zero
    r0 <- rast0 + rastRandom
    r0 <- terra::ifel(r0 < trueNeg, 1, rast0)
    # one 
    r1 <- rast1 + rastRandom
    r1 <- terra::ifel(r1 > truePos, 1, rast1)
    
    # add results -- removes all NA values 
    rSum <- terra::app(c(r0, r1), fun = sum, na.rm = TRUE)
    # add back in the NA values from the original image 
    naRast <- ifel(is.na(rast), NA, 1)
    # Multiple to bring in the NA  
    rSum <- rSum * naRast 
    
    # examples of difference 
    diff <- rast - rSum
    terra::plot(diff)
    return(rSum)
}

  
}








