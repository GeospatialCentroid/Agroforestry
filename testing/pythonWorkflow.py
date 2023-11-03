import ee
import os
import geemap 
import geopandas as gpd
# earthengine calls 
ee.Initialize()





def generateRFModel(aoiID,year,grid,ne,size, compactness, connectivity):
  

  
  # this is the general areas of interest the feature that we will be itoreting over
  # aoiID = 'X12-695'
  # year 
  # year = 2016
  # reference grid opbject
  # grid = gpd.read_file("data/twelve_mi_grid_uid.gpkg")
  ### as geopandas class 
  aoi_pandas = grid[grid.Unique_ID == aoiID]
  
  # load in a state layer as a reference 
  # ne = pdg.read_file("data/referenceData/nebraska_counties.gpkg")
  aoi_ne =  geemap.gdf_to_ee(ne)
  ### as ee object -- used to determine where the model is applied 
  aoi_ee = geemap.gdf_to_ee(aoi_pandas)
  
  ## read in point data
  filePath = "C:/Users/carverd/Documents/GitHub/Agroforestry/testing/data/testSamplingData.geojson"
  # read in data 
  s = gpd.read_file(filePath)
  # convert to an ee object 
  sp1 = geemap.gdf_to_ee(points)
  
  # map to show relative locations of features 
  # ax = aoi_pandas.plot(color="palegreen", edgecolor="green", figsize=(20, 10))
  # s.plot(ax=ax, color="red")
  # plt.show()
  # 
  
  # grab naip for area and year 
  naip1 = geemap.get_annual_NAIP(year).filterBounds(sp1).mosaic() # 
  # generate NDVI 
  ndvi = naip1.normalizedDifference(["N","R"])
  # add ndvi to naip image 
  naip = naip1.addBands(ndvi)
  
  
  # parameters for the segmentation process

  # run the segementation
  snic = ee.Algorithms.Image.Segmentation.SNIC(naip,size,compactness,connectivity)
  # select specific bands and combine with original image
  snicModel = snic.select('R_mean', 'G_mean', 'B_mean','N_mean', "nd_mean").addBands(naip)
  
  ## Extract values to points 
  extract_vals = snicModel.sampleRegions(collection=sp1, scale=1)
  # print(extract_vals.getInfo())
  # easiest print statement
  geemap.ee_to_gdf(extract_vals)
  
  
  # generate a rf model 
  trainingclassifier = ee.Classifier.smileRandomForest(numberOfTrees = 10, seed = 7).train(features= extract_vals,classProperty = 'presence')
  
  confusionMatrix = trainingclassifier.confusionMatrix()
  # print(confusionMatrix.getInfo())
  
  return trainingclassifier, confusionMatrix

def applyRFModel()
# generate the RF classifier

vals = generateRFModel(aoiID= aoiID, year=year,grid=grid,ne=ne,points=points,size=size,compactness=compactness,connectivity=connectivity)


  
  
