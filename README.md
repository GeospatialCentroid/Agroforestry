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
