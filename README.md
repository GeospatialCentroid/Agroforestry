# Agroforestry

Generic method for detection of non forested trees within Nebraska

## Summary of the work flow 

Important files 


## Organization of repository

|- flowcharts/ : storage for concept and workflow charts generated with draw.io

|- agroforestry/: functions defined as part of this project, this contains the code that is dependent on the python processing steps. 

    |- __init__.py  :defines repo as package

    |-  config.py : established consistent parameters/environment elements

    |- {functions}.py : groups of functions used to support overall workflow. 

|- data/

   |- raw : data downloaded from an external source

   |- processed : intermediate and processed datasets

   |- products : finalized datasets that can be shared

|- README.md : summary of the processing steps connecting raw to product
   
|- mapProducts/ : images and off of map features used to support a reporting step of the project. (not finalized outputs)

|- referenceMaterial/ : physical copies of important peer reviewed students that are guiding this work. 

|- scripts/ : The location of R scripts used in data processing after the models have been produced 

    |- functions/ : functions used within the R scripts within this folder 
    
    |- tempOrSingleUse/ : often material developed for examples or one off data produces/analysis

|- requirements.txt : specifics about the library requirements of for the project


## Generalized workflow 

![general workflow](./flowcharts/agroforestryOverview.svg)



## Maintainer

[dcarver1](https://github.com/dcarver1)



## methods notes 

**gather 2x miles girds for validation**
- 1. define2mSubGrids.R : use this to generate a file that selects two mile subgrids within the model area that are off full area 
  - note export path must be editied within the funciton to over write 
  - some edits for a single feature run rather then the full year... works but not really attended use so careful 
  
- 2. renderSelectedSubGrids.R : used the selected two mile sub grid to gather the correct classification and then crop to two mile grid 
  - pretty easy to adapt to single feature run as 2-mile gird id is stored in the export path 
  
- 3. pullNAIPforSubGridValidation.py : python with GEE interactino 
  - manually update the year, sub grids and run.
  - might want to alter export from GEE to exclude the 4th band as it tends to assign that to a transparency layer when loaded into QGIS 
  





