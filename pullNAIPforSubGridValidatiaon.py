import ee
import geemap
import pandas as pd
import geopandas as gpd

# ee.Authenticate(auth_mode = 'notebook')
ee.Initialize(project='agroforestry2023')

m2 = gpd.read_file("data/products/two_sq_grid.gpkg")
  
# redefine for 2016 match run 
grids = [2211,5253, 185,2403,4077,4211,14116,19856,20583,7382,6834,9158,19495,25117,19292,28541,29226,26031,30672,25981,27018,
     2491,3138,802,1806,1362,6621,4454,6847,10651,6765,12560,8876,9490,21150,25329,30351,29209,26346,28277,27788,28485,
     691,3739,1686,1203,5902,7532,10203,18647,18517,6465,10745,8869,9517,19633,15679,24011,28298,24827,24936,30210,20682,
     4604,4043,5313,4215,2872,589,11723,8053,15192,7346,6229,18842,16738,24201,26535,17095,22880,26060,27086,28088,25495]
# export 
for i in range(len(grids)):
    print(i)
    val = grids[i]
    year = "2010"
    # select subgrid 
    grid = m2.loc[m2['FID_two_grid'] == val]
    subgrid = grid.iloc[0,0]
    gee1 = geemap.gdf_to_ee(grid)
     # select naip and export for each grid 
    naip1 = geemap.get_annual_NAIP(year).filterBounds(gee1).mosaic()  
    # description 
    description = "subgrid_" + str(subgrid)+"_year_"+str(year)
    # export image to asset
    task = ee.batch.Export.image.toDrive(
            image=naip1,
            description=description,
            folder=str(year),
            region=gee1.geometry(),
            scale=1,
            crs= naip1.projection(),
            maxPixels=1e13
        )
    task.start()
 

# initial attempt 
# read in all grid feature 
# grids = pd.read_csv("data/products/selectedSubGrids/allSelectedGrids.csv")

# # read in 2 mile grid 
# m2 = gpd.read_file("data/products/two_sq_grid.gpkg")

# # ee.Authenticate(auth_mode = 'notebook')
# ee.Initialize(project='agroforestry2023')

# # read in all grid feature 
# grids = pd.read_csv("data/products/selectedSubGrids/allSelectedGrids.csv")

# # # read in 2 mile grid 
# # 
# for i in range(len(grids)):
#     row = grids.iloc[i]
#     model = row.iloc[0]
#     year = row.iloc[1]
#     for j in range(2,6):
#         grid = m2.loc[m2['FID_two_grid'] == row.iloc[j]]
#         subgrid = grid.iloc[0,0]
#         gee1 = geemap.gdf_to_ee(grid)
#         # select naip and export for each grid 
#         naip1 = geemap.get_annual_NAIP(year).filterBounds(gee1).mosaic()  
#         # description 
#         description = model + "_" + "subgrid_" + str(subgrid)+"_year_"+str(year)
#         # export image to asset
#         task = ee.batch.Export.image.toDrive(
#             image=naip1,
#             description=description,
#             folder=str(year),
#             region=gee1.geometry(),
#             scale=1,
#             crs= naip1.projection(),
#             maxPixels=1e13
#         )
#         task.start()



