# aerialPhotoFrame
Create a spatial polygon (`sf`) delineating the ground extent (AKA wireframe or
field of view) of a nadir photo taken from an airplane or drone.
Useful in approximating the locations and total area sampled in a series of
aerial photos.

## Input
+ Photos which contain EXIF metadata specifying the GPS location of the camera
(X, Y, Z coordinates) when the photo was taken, the photo timestamp, and
information about the photo's aspect ratio and field of view with the camera's
sensor dimensions and lens focal length.

## Output
+ An `sf` object approximating the area photographed in each photo.

## General Workflow
+ `extractPoints` - Extract camera location (3D point) from photos, and
approximate the direction of travel (and therefore photo orientation) from the
sequence of photo locations.
+ `calcAlt` - Download a digital elevation model (DEM) for the
study area and calculate the camera's approximate altitude above ground level
based on the camera's altitude above mean sea level (what the GPS records) and 
the ground elevation (from the DEM).
+ `wireFrame` - Use EXIF-provided camera and lens specifications, altitude,
and direction of travel to construct rectangular wireframe of each photo's
ground extent

## Key Dependencies
+ The EXIF data associated with photos is read using the `exifr` package, which
calls [ExifTool](https://exiftool.org/)
+ The DEM for the study area is downloaded using the `FedData` package, which
obtains DEMs from the [USGS National Elevation Dataset (NED)](https://www.usgs.gov/3d-elevation-program).
