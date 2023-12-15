# big function that produces the segementation model 


def snicOutputs(naip, SNIC_SeedShape, SNIC_SuperPixelSize, SNIC_Compactness, SNIC_Connectivity, bandsToUse_Cluster):
    import geemap
    import ee
    # develop a seed grid for the segemetation process
    seed1 = ee.Algorithms.Image.Segmentation.seedGrid(size = SNIC_SuperPixelSize,
                                                         gridType = SNIC_SeedShape)

       # run the cluster algorytm
    snic = ee.Algorithms.Image.Segmentation.SNIC(image = naip,
                                                    # size = SNIC_SuperPixelSize,
                                                    compactness = SNIC_Compactness,
                                                    connectivity = SNIC_Connectivity,
                                                    # neighborhoodSize = SNIC_NeighborhoodSize, 
                                                    seeds = seed1)
       
       # reproject to ensure that clusters are drawn at the native resolution
       # some issues with this step... come back to ti. 
       # snic_Proj=snic.reproject(crs = 'EPSG:3857', scale = nativeScaleOfImage)

        # select specific bands and combine with original image
    snic2 = snic.select(bandsToUse_Cluster).addBands(naip)
    return snic2
