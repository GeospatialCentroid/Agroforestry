pacman::p_load(terra, here)

here()
t1 <- rast("data/naip2016Antelope/naip1.tif")
t1
plot(t1)
# rename to standard colors 
names(t1) <- c("r","g","b","nr")
plotRGB(t1)

# (NIR - R) / (NIR + R)
ndvi <- (t1$nr - t1$r)/(t1$nr + t1$r)
plot(ndvi)
