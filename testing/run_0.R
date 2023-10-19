# primary script for rendering the classification and segementation worksflow 

pacman::p_load(dplyr, terra, readr, sf, reticulate)

reticulate::use_virtualenv(virtualenv = "agro-env")
