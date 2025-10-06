

files <- list.files("data/products/changeOverTime",
                    pattern = "_2.tif",
                    full.names = TRUE)
# single 
g <- files[grepl(pattern = "418", x = files)]

# write for easier trasfer 
file.copy(from = g, to = "data")
