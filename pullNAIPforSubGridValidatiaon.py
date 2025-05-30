import ee
import geemap
import pandas as pd
import geopandas as gpd

# ee.Authenticate(auth_mode = 'notebook')
ee.Initialize(project='agroforestry2023')

# read in all grid feature 
grids = pd.read_csv("data/products/selectedSubGrids/allSelectedGrids.csv")

# read in 2 mile grid 
m2 = gpd.read_file("data/products/two_sq_grid.gpkg")

m2ee = geemap.gdf_to_ee(m2)
# 
for i in range(len(grids)):
    row = grids.iloc[i]
    model = row.iloc[0]
    year = row.iloc[1]
    for j in range(2,6):
        grid = m2.loc[m2['FID_two_grid'] == row.iloc[j]]
        subgrid = grid.iloc[0,0]
        gee1 = geemap.gdf_to_ee(grid)
        # select naip and export for each grid 
        naip1 = geemap.get_annual_NAIP(year).filterBounds(gee1).mosaic()  
        # description 
        description = model + "_" + "subgrid_" + str(subgrid)+"_year_"+str(year)
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