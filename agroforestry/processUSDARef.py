def processUSDARef(aoiGrid, usdaRef):
    import geopandas as gpd
    # select all tree related elements 
    trees = usdaRef[usdaRef.LCC != 0] # [usdaRef.LCC in [1,2,3,4,5,6]]
    # reproject the data
    treesProj = trees.to_crs(aoiGrid.crs)
    #clip the feature to aoi
    treesClipped = treesProj.clip(aoiGrid)
    # add reference value and drop the rest 
    treesClipped["presence"] = 1
    # select column --- this is producing some weird stuff... so I'm ignoring it for now.  
    # treesProcessed = treesClipped[["presence"]]
    return(treesClipped)


    