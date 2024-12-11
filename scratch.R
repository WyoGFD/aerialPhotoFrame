# How to rotate an sf object
# Source:  https://r-spatial.github.io/sf/articles/sf3.html#affine-transformations


require(sf)

nc = st_read(system.file("shape/nc.shp", package="sf"), quiet = TRUE)
ncg = st_geometry(nc)
plot(ncg, border = 'grey')
cntrd = st_centroid(ncg)
rot = function(a) matrix(c(cos(a), sin(a), -sin(a), cos(a)), 2, 2)
# rotate by 90 degrees, resize to 75% of original 
ncg2 = (ncg - cntrd) * rot(pi/2) * .75 + cntrd
plot(ncg2, add = TRUE)
plot(cntrd, col = 'red', add = TRUE, cex = .5)


# Check area
sum(st_area(ncg))
sum(st_area(ncg2))

require(units)
bearing_deg <- as_units(90, "degrees")
bearing_rad <- set_units(bearing_deg, "radians")


