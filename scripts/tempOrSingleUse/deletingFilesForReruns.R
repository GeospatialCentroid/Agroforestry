


### deleting 2010 masked model runs to fix an issues with no zero values being assigned 
# delele 2010 files 
## run run generate Masked Images 
# delete COT files 
## rerun changeOVerTime 
gridIDs <- c("X12-319","X12-366",  "X12-367","X12-413",  "X12-513","X12-514", 
             "X12-515","X12-516",  "X12-517","X12-559",  "X12-560","X12-561", 
             "X12-562","X12-563",  "X12-604","X12-605",  "X12-606","X12-607",  
             "X12-608","X12-649",  "X12-650","X12-651",  "X12-652","X12-653",  
             "X12-694","X12-695",  "X12-696","X12-697",  "X12-698")

# masked file locatinos 
maskFiles <- list.files("data/products/models2010/maskedImages",
                        full.names = TRUE)

# delete mask files for 2010 
for(i in gridIDs){
  print(i)
  file <- maskFiles[grepl(pattern = i, x = maskFiles)]
  # file.remove(file)
}

# cot files 
cotFiles <- list.files("data/products/changeOverTime",
                        full.names = TRUE)
# delete mask files for 2010 
for(i in gridIDs){
  print(i)
  file <- cotFiles[grepl(pattern = paste0(i, "_changeOverTime_2"), x = cotFiles)]
  # file.remove(file)
}
