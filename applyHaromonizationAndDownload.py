import ee
ee.Initialize()

# try:
#         ee.Initialize()
# except Exception as e:
#         ee.Authenticate(auth_mode = 'notebook') # to force browser popup. Unsucessful with gcloud cmd based authentications. 
#         # ee.Initialize()


import os, time
from datetime import datetime
import geemap
import geopandas as gpd
import pandas as pd
import numpy as np
# from agroforestry1.snicProcessing import *
# from agroforestry1.randomForest import *
from agroforestry1.histMatch import *

# ###############################################################################################################
year = 2010
target_grids = [ "X12-319","X12-318", "X12-366", "X12-367"] #  
# c("X12-179", "X12-227", "X12-103", "X12-141") 
reference_grids = ['X12-318', "X12-318", "X12-318", "X12-318" ] # refence grid for 318 

grid = gpd.read_file('data/processed/griddedFeatures/twelve_mi_grid_uid.gpkg')
g2 = gpd.read_file('data/processed/griddedFeatures/twelve_mi_grid_uid.gpkg')

# ###############################################################################################################

human_readable = datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d %H:%M:%S')
print('Creating classified agroforestry maps using grid-specific features:')
print(f'Execution started at at {human_readable}')
print(f'Processing files for year {year}...')
grids = gpd.read_file(f'data/products/modelGrids_{year}.gpkg')

for tar_grid in target_grids:
    # print(f'Processing started for target (mapped) grid {tar_grid} and reference (classifier) grid {ref_grid}...')
    ################################ generate map for self-harmonized image ###################################

    
    grid_to_map = grids.loc[grid.Unique_ID == tar_grid]
    gridArea = geemap.gdf_to_ee(grid_to_map)
    matched_naip = matchSelf(gridArea=gridArea, year=year)
    description = 'self_harmonized_naip_' + str(tar_grid) + '_' + str(year)
    print(' -> Saving to Google Drive: ' + description)
    task = ee.batch.Export.image.toDrive(
            image=matched_naip,
            description=description,
            folder=str(year),
            region=gridArea.geometry(),
            scale=1,
            crs= matched_naip.projection(),
            maxPixels=1e13
    )
    task.start()
    ################################ generate map for ref-harmonized image ###################################
#     try:
#         ref_grid_to_map = grids.loc[grid.Unique_ID == ref_grid]
#         ref_gridArea = geemap.gdf_to_ee(ref_grid_to_map)
#         ref_naip = getNAIP(gridArea=ref_gridArea, year=year)

#         tar_grid_to_map = grids.loc[grid.Unique_ID == tar_grid]
#         tar_gridArea = geemap.gdf_to_ee(tar_grid_to_map)
#         matched_naip = matchGrid(gridIDs=[tar_grid], referenceImage=ref_naip, year=year)

#         description = 'ref_harmonized_naip_' + str(tar_grid) + "_using_" + ref_grid + '_' + str(year)
#         print(' -> Saving to Google Drive: ' + description)
#         # export image to asset
#         task = ee.batch.Export.image.toDrive(
#             image=matched_naip,
#             description=description,
#             folder=str(year),
#             region=tar_gridArea.geometry(),
#             scale=1,
#             crs=matched_naip.projection(),
#             maxPixels=1e13
#         )
#         task.start()