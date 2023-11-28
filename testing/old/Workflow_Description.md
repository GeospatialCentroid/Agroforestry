# description of the modeling and segementation workflow 

- Utilize Functions to complete specific steps. 




### Organized at the Collection Grid level

**inputs** : 

- lat lon values from a sampling location 

- reference grid object


1. train a RF model within GEE based on the input sampling data (python)

2. For each aoi, generate a subgrid feauture (r)

3. itorate of the subgrid projecting the model and downloading the resulting binary raster

4. bind all the outfiles to single feature and delete the smalled subsets

5. evaluated the projected rasted against the known dataset. 
- statistics hear influence the segementation parameterization as well as goal %PCC for future RF Models

