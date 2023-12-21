PRobably not going stick with pip... we shall see. 


# why Conda 

There has been a number of installation dependecy issues related to GDAL install via pip. There is surely a viable option out there for pip install of GDAL, but it's currently provide more trouble then it's worth to find and impliment. As a result conda is being utilized. 


## Install steps. 
We are following the basic download and configeration define in the `referenceMaterial` folder. Choose your file based on your OS. 
Thanks to the NASA DEVELOP program for generating this material. 

## Conda environment. 
This may adapt overtime as package dependcy grows but for now use the following lines of code to establish conda environemnt for this project 
```bash 
conda create -n agroforestryDetection -c conda-forge -y jupyterlab numpy matplotlib xarray rasterio geopandas earthengine-api geemap jupyter_contrib_nbextensions 

```

I was unable to install all of this in single call so I did the following 

Still not working but getting there. 

```bash 
conda create -n agroforestryDetection -c conda-forge -y jupyterlab numpy 

conda activate agroforestryDetection

conda install geemap -c conda-forge
conda install rasterio 
conda install --channel conda-forge geopandas

conda 
matplotlib xarray rasterio geopandas earthengine-api geemap jupyter_contrib_nbextensions 

```



