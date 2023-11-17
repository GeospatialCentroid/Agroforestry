# Agroforestry

Generic method for detection of non forested trees within Nebraska

## Organization of repository
Following the strucutre outline [here](https://gist.github.com/ericmjl/27e50331f24db3e8f957d1fe7bbbe510). It might get adjusted overtime, but I'm going to try to follow it closely until there is very good reason too.

|- notebooks : storeage for .ipynb files

|- flowcharts : storage for concept and workflow charts generated with draw.io

|- agroforestry: functions defined as part of this project

    |- __init__.py  :defines repo as package

    |-  config.py : established consistent parameters/environment elements

    |- functions.py : there will be many with unique descriptive names

    |- test_{stuff}.py : not sure if this will be implimented or not

|- data

   |- raw : data downloaded from an external source

   |- processed : intermediate and processed datasets

   |- products : finalized datasets that can be shared

   |- README.md : summary of the processing steps connecting raw to products

|- scripts/ : ideally some of the workflow script live in here but I can't get the sourcing function to work well so until then they will live in the primary folder.

    |- archive/ : storage for workflow script that are no longed used

|- script1.py : workflow scripts

|- requirements.txt : specifics about the library requirements of for the project






## Summary

*What are you attempting to answer with this project?*

-   Using publicly available aerial imagery we plan to develop a classification process the distinguishes trees outside of forests from other features across a wide geographic area.

*What measures will be used to determine a successful project?*

-   A successful methodology will allow us to apply this classification across the state of Nebraska at three distinct time periods (2010,2015,2020). We will continue to work with project partner to understand what level of classification accuracy is acceptable for there needs.

*What is the final product and what value do it add?*

-   The classification process will be embedded within a docker to enable stable distribution and consistent of results.

-   A binary map of trees outside of forests for the state of Nebraska for years 2010,2015, and 2020 will be used to develop improved estimates of carbon storage of these biological features.

-   This is a large pilot project. A report highlight the expected ease at which this process can be applied to different geographic areas will support any future effort in expanding the carbon accounting work.

*How do you know when it is time to stop spending time on this project?*

-   The area of analysis is limited too the state of Nebraska.

-   The project is budget constrained.

-   All funds must be spent out by July 2024.

## Expected timeline

**December 2023** : methodology solidified and initial results produced to support a presentation at AGU

**March 2023** : Finalized map produced delivered to project partners.

**July 2024** : All funding spent.

## Description of Project Stages

### Stage 1: Replicating results from an existing study to evaluate the effectiveness of the methods.

-   Researchers confidently apply the segmentation and classification methodology to any area where trees outside of forest have previously been mapped.

-   Quantitative measure of accuracy against existing data sets to establish as accept accuracy value for the rest of the study.

-   Tuned model parameters for both the image segmentation process and classification algorithm become the base for testing the method at different spatial and temporal locations.

### Stage 2: Independently evaluating how the segmentation and classification models can detect trees outside forests in a distinct geographic areas.

-   Hand digitized validation maps of trees outside forest will be produce at represenative testing locations across the state.

-   Trees outside of forests are modeled and accuracy is assessed against user created vaildation maps.

-   An evaluation of the extent to which the initial models can be applied to different geographic locations is generated to allow for the prediction of how many unique models will be required to capture the ecological variability within the state.

### Stage 3: Evaluate the effectiveness of the segmentation and classification models across specific time ranges.

-   Technicians develop validation maps of trees outside forest across the state at different time periods using the same testing site defined in stage 2.

-   Tree cover is modeled and accuracy is assessed against user created maps.

-   An evaluation of the extent to which the initial models can be applied to different years and image sets is generated.

### Stage 4: Test methods for developing a mask layer that can be applied to limit the area of analysis required to perform a classification on.

-   Evaluate at least state level (ideally national) layers that can be used as a mask for the NAIP imagery.

-   Test the effect of these mask layers on the evaluate sites defined in Stage 1:3 to determine

    -   changes in process run time

    -   change in classification accuracy

### Stage 5: Containerize the modeling process

-   develop a docker container that can flexible handle user inputs on model selection, year of classification and AIO.

### Stage 6: Apply the segmentation and classification model to the full area of interest for 2010, 2015, 2020.

-   Develop a visually sampled point based validation set that can be used for all three time periods

-   A state level layer that identifies the location of trees outside of forests.

-   Validated the spatial classification looking specifically for any regions with high observed areas as this would represent an over reach a specific model.

### Stage 7: Make the continued development of this work as seamless as possible.

-   Develop a report noting the considerations and limitations that should be accounted for when attempting to apply the process to a new geographic area

-   Suggestions on how best to expand the work based on geographic regions.

-   Direct support during the analysis and publication process.

## Maintainer

[dcarver1](https://github.com/dcarver1)
