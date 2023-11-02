# image = naip
# size = 30
# compactness = 0.1
# connectivity = 8
# 
# 
# runSegmentation(naip,size,compactness, connectivity)

def runSegmentation(image,size,compactness,connectivity):
  # run the segementation
  snic = ee.Algorithms.Image.Segmentation.SNIC(image,size,compactness,connectivity)
  # select specific bands and combine with original image
  snicModel = snic.select('R_mean', 'G_mean', 'B_mean','N_mean', "nd_mean").addBands(image)
  return(snicModel)

