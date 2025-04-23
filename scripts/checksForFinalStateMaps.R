###
# indentify any missing elements from the various modelling steps 
#
### 

pacman::p_load(dplyr, terra)

# grid 
grid <- terra::vect("data/processed/griddedFeatures/twelve_mi_grid_uid.gpkg")
g10 <- terra::vect("data/products/modelGrids_2010.gpkg")
g16 <- terra::vect("data/products/modelGrids_2010.gpkg")
g20 <- terra::vect("data/products/modelGrids_2010.gpkg")
# NA rows in grids 
# g10 : 	X12-336 X12-740
# g16 : 	X12-336 X12-740
# g20 : 	X12-336 X12-740



# all features 
allGrids <- as.data.frame(g10)|> 
  bind_rows(as.data.frame(g16)) |> 
  bind_rows(as.data.frame(g20))
# unique grid IDs -- 773 unique model grids
uniqueGridIDs <- unique(allGrids$Unique_ID)
length(uniqueGridIDs)
# unique Model ids -- 26 unique model areas 
uniqueModelIds <- unique(allGrids$modelGrid)
uniqueModelIds <- uniqueModelIds[!is.na(uniqueModelIds)] |> sort()


# modeling method 
# ## training data : raw/grid name  ---------------------------------------
folders <- list.files(path = "data/raw",
                      full.names = TRUE)
f1 <- folders[grepl(pattern = "/X12-", x = folders)] |> sort()
# test what model areas are not present in folders 
missingModelData <- uniqueModelIds[!uniqueModelIds %in% basename(f1) ]
## 

# # fullimages - combined images from GEE  : products/models*year* --------
d10 <- list.files("data/products/models2010/fullImages")
d16 <- list.files("data/products/models2016/fullImages")
d20 <- list.files("data/products/models2020/fullImages") 
## check to see if all grids are present in list of files 
subsetGridID <- function(data){
  d2 <- data |> stringr::str_split(pattern = "_") |> unlist()
  d2 <- d2[d2 != "fullUnMasked.tif"]
  d2 <- d2[d2 != "harmonized"] |> unique()
  return(d2)
}
missing10 <- uniqueGridIDs[!uniqueGridIDs %in% subsetGridID(d10)]
missing16 <- uniqueGridIDs[!uniqueGridIDs %in% subsetGridID(d16)]
missing20 <- uniqueGridIDs[!uniqueGridIDs %in% subsetGridID(d20)]
# all of these areas will need to be remodeled 


# ## maskedImages - processed images to exclude cities and forest  --------
d10m <- list.files("data/products/models2010/maskedImages")
d16m <- list.files("data/products/models2016/maskedImages")
d20m <- list.files("data/products/models2020/maskedImages") 
# errors in the masking process 
missing10_mask <- uniqueGridIDs[!uniqueGridIDs %in% subsetGridID(d10m)]
missing10_mask <- missing10_mask[!missing10_mask %in% missing10]

missing16_mask <- uniqueGridIDs[!uniqueGridIDs %in% subsetGridID(d16m)]
missing16_mask <- missing16_mask[!missing16_mask %in% missing16]

missing20_mask <- uniqueGridIDs[!uniqueGridIDs %in% subsetGridID(d20m)]
missing20_mask <- missing20_mask[!missing20_mask %in% missing20]
### so for any location that we were able to produce a model we were also able to generate a masked model


# ## maskedRiparianImages - processed images to include riparian o --------
d10r <- list.files("data/products/models2010/maskedImages")
d16r <- list.files("data/products/models2016/maskedImages")
d20r <- list.files("data/products/models2020/maskedImages") 
# errors in the masking process 
missing10_rip <- uniqueGridIDs[!uniqueGridIDs %in% subsetGridID(d10r)]
missing10_rip<- missing10_rip[!missing10_rip%in% missing10]

missing16_rip<- uniqueGridIDs[!uniqueGridIDs %in% subsetGridID(d16r)]
missing16_rip<- missing16_rip[!missing16_rip %in% missing16]

missing20_rip <- uniqueGridIDs[!uniqueGridIDs %in% subsetGridID(d20r)]
missing20_rip <- missing20_rip[!missing20_rip %in% missing20]
### so all locations were models were generated the riparian layer was effectively applied 


# Combined models ---------------------------------------------------------
cM <- list.files(path = "data/products/changeOverTime",
                 pattern = ".tif") |>
  subsetGridID() |>
  unique()

missing_cot <- uniqueGridIDs[!uniqueGridIDs %in% cM]
# Check to see if any missing ids are not present in the missing model data 
errored_cot <- missing_cot[!missing_cot %in% missing10]
errored_cot <- errored_cot[!errored_cot %in% missing16]
errored_cot <- errored_cot[!errored_cot %in% missing20]
## single grid X12-413 is producing an error within the change over time method. 

