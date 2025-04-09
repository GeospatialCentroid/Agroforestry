pacman::p_load(terra)

# remove the water and ice from forest features 
r1 <- terra::rast("data/processed/canopyHeight/Forest_height_2019_neb.tif")
# reclass 
# You can also use a data frame for the reclassification rules
reclass_df_range <- data.frame(
  from = c(101, 102, 103),
  to = c(NA, NA, NA) # Use Inf for open-ended upper ranges
)
r2 <- classify(r1, reclass_df_range)
# export 
#terra::writeRaster(x = r2, filename = "data/processed/canopyHeight/Forest_height_2019_neb_treesOnly.tif")



# test the integrations of the layers 
d1 <- terra::rast("data/products/changeOverTime/X12-356_changeOverTime_2.tif")
# reclass to 2016 
reclass2016 <- data.frame(
  from = c(1,3,4,5,6,8,9),
  to = c(0,1,1,0,1,0,1) # Use Inf for open-ended upper ranges
)
d2 <- terra::classify(x = d1$ChangeOverTime, reclass2016)
# attempt multiplication 
r3 <- terra::crop(r2, d2)
r3_resampled <- resample(r3, d2, method="bilinear")
d3 <- d2 * r3_resampled
# export 
terra::writeRaster(x = d3, filename = "data/processed/canopyHeight/X12-356_canopyheight2016.tif")
