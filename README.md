# Agroforestry

Generic method for detection of non forested trees within Nebraska

## Summary of the work flow 

Important files 










## Organization of repository
Following the strucutre outline [here](https://gist.github.com/ericmjl/27e50331f24db3e8f957d1fe7bbbe510). It might get adjusted overtime, but I'm going to try to follow it closely until there is very good reason too.

|- notebooks/ : storeage for .ipynb files

|- flowcharts/ : storage for concept and workflow charts generated with draw.io

|- agroforestry/: functions defined as part of this project

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

|- sampling/ : abandoned workflow to sample within an .ipynb. Completling sampling within the GEE web interface. 

|- scripts/ : ideally some of the workflow script live in here but I can't get the sourcing function to work well so until then they will live in the primary folder.

    |- archive/ : storage for workflow script that are no longed used

|- script1.py : workflow scripts

|- requirements.txt : specifics about the library requirements of for the project

|- referenceMaterial : Supporting files and documentation related to method develop or environment setup 





## Maintainer

[dcarver1](https://github.com/dcarver1)
