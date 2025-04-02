# aerialPhotoFrame


Create a spatial polygon (`sf`) delineating the ground extent (AKA
wireframe or field of view) of a nadir photo taken from an airplane or
drone. Useful in approximating the locations and total area sampled in a
series of aerial photos.

## How to Install

From GitHub:

    remotes::install_github("https://github.com/WyoGFD/aerialPhotoFrame")

## Input

- Photos which contain EXIF metadata specifying the GPS location of the
  camera (X, Y, Z coordinates) when the photo was taken, the photo
  timestamp, and information about the photo’s aspect ratio and field of
  view with the camera’s sensor dimensions and lens focal length.

## Output

- An `sf` object approximating the area photographed in each photo.

## General Workflow

- `extractPoints` - Extract camera location (3D point) from photos, and
  approximate the direction of travel (and therefore photo orientation)
  from the sequence of photo locations.
- `calcAlt` - Download a digital elevation model (DEM) for the study
  area and calculate the camera’s approximate altitude above ground
  level based on the camera’s altitude above mean sea level (what the
  GPS records) and the ground elevation (from the DEM).
- `wireFrame` - Use EXIF-provided camera and lens specifications,
  altitude, and direction of travel to construct rectangular wireframe
  of each photo’s ground extent

## Key Dependencies

- The EXIF data associated with photos is read using the `exifr`
  package, which calls [ExifTool](https://exiftool.org/)
- The DEM for the study area is downloaded using the `FedData` package,
  which obtains DEMs from the [USGS National Elevation Dataset
  (NED)](https://www.usgs.gov/3d-elevation-program).

## Example

The package contains 5 example aerial photos collected in Southern
Wyoming in February 2025. They are located in the `extdata` folder of
the installed package (e.g.,
`C:/Users/jadcarlisle/Documents/R/aerialPhotoFrame/extdata`).

![image info](ExamplePhotos_Thumbnail.JPG)

``` r
# Load package
library(aerialPhotoFrame)
```

    aerialPhotoFrame (version 0.9.1)

``` r
# Path to installed package to access example images
packagePath <- "C:/Users/jadcarlisle/Documents/R/aerialPhotoFrame"

# Extract camera location from photos
pts <- extractPoints(file.path(packagePath,
                               "extdata"))
```

    Date in ISO8601 format; converting timezone from UTC to "MST".

``` r
# View first few rows
head(data.frame(sf::st_drop_geometry(pts)))
```

             FileName
    1 Image_25042.JPG
    2 Image_25043.JPG
    3 Image_25044.JPG
    4 Image_25045.JPG
    5 Image_25046.JPG
                                                                     SourceFile
    1 C:/Users/jadcarlisle/Documents/R/aerialPhotoFrame/extdata/Image_25042.JPG
    2 C:/Users/jadcarlisle/Documents/R/aerialPhotoFrame/extdata/Image_25043.JPG
    3 C:/Users/jadcarlisle/Documents/R/aerialPhotoFrame/extdata/Image_25044.JPG
    4 C:/Users/jadcarlisle/Documents/R/aerialPhotoFrame/extdata/Image_25045.JPG
    5 C:/Users/jadcarlisle/Documents/R/aerialPhotoFrame/extdata/Image_25046.JPG
                 DateTime ImageWidth ImageHeight Megapixels FocalLength
    1 2025-03-01 14:22:49       8256        5504   45.44102          50
    2 2025-03-01 14:22:51       8256        5504   45.44102          50
    3 2025-03-01 14:22:53       8256        5504   45.44102          50
    4 2025-03-01 14:22:55       8256        5504   45.44102          50
    5 2025-03-01 14:22:57       8256        5504   45.44102          50
                         FOV RollAngle PitchAngle  YawAngle      Bearing
    1 39.597786155869 0.0072 -171.4419  -92.63480 -90.25375 89.81921 [°]
    2 39.597786155869 0.0072  161.6159  -90.82028 -89.53882 89.59467 [°]
    3 39.597786155869 0.0072 -119.5836  -92.34445 -94.14117 89.98836 [°]
    4 39.597786155869 0.0072 -142.0549  -92.94086 -92.22449 89.94630 [°]
    5 39.597786155869 0.0072  146.9061  -93.25247 -87.56607 89.94630 [°]

``` r
# Map
plot(sf::st_geometry(pts))
```

![](README_files/figure-commonmark/unnamed-chunk-1-1.png)

``` r
# Add altitude, specifically above-ground-level
pts <- calcAltitude(pts)
```

    Area of interest includes 1 NED tiles.

    (Down)Loading NED tile for 42N and 108W.

``` r
# View first few rows
# Note new columns starting within Altitude
head(data.frame(sf::st_drop_geometry(pts)))
```

             FileName
    1 Image_25042.JPG
    2 Image_25043.JPG
    3 Image_25044.JPG
    4 Image_25045.JPG
    5 Image_25046.JPG
                                                                     SourceFile
    1 C:/Users/jadcarlisle/Documents/R/aerialPhotoFrame/extdata/Image_25042.JPG
    2 C:/Users/jadcarlisle/Documents/R/aerialPhotoFrame/extdata/Image_25043.JPG
    3 C:/Users/jadcarlisle/Documents/R/aerialPhotoFrame/extdata/Image_25044.JPG
    4 C:/Users/jadcarlisle/Documents/R/aerialPhotoFrame/extdata/Image_25045.JPG
    5 C:/Users/jadcarlisle/Documents/R/aerialPhotoFrame/extdata/Image_25046.JPG
                 DateTime ImageWidth ImageHeight Megapixels FocalLength
    1 2025-03-01 14:22:49       8256        5504   45.44102          50
    2 2025-03-01 14:22:51       8256        5504   45.44102          50
    3 2025-03-01 14:22:53       8256        5504   45.44102          50
    4 2025-03-01 14:22:55       8256        5504   45.44102          50
    5 2025-03-01 14:22:57       8256        5504   45.44102          50
                         FOV RollAngle PitchAngle  YawAngle      Bearing
    1 39.597786155869 0.0072 -171.4419  -92.63480 -90.25375 89.81921 [°]
    2 39.597786155869 0.0072  161.6159  -90.82028 -89.53882 89.59467 [°]
    3 39.597786155869 0.0072 -119.5836  -92.34445 -94.14117 89.98836 [°]
    4 39.597786155869 0.0072 -142.0549  -92.94086 -92.22449 89.94630 [°]
    5 39.597786155869 0.0072  146.9061  -93.25247 -87.56607 89.94630 [°]
      AltitudeCamera AltitudeGround  AltitudeAGL
    1   2168.104 [m]   1870.021 [m] 298.0835 [m]
    2   2164.875 [m]   1858.686 [m] 306.1891 [m]
    3   2160.944 [m]   1858.452 [m] 302.4921 [m]
    4   2161.907 [m]   1859.270 [m] 302.6370 [m]
    5   2165.680 [m]   1865.929 [m] 299.7506 [m]

``` r
# Histogram of camera altitudes above ground level
hist(pts$AltitudeAGL,
     main = "Histogram of Camera Altitudes",
     xlab = "Altitude above ground level")
```

![](README_files/figure-commonmark/unnamed-chunk-2-1.png)

``` r
# Create wireframe of each photo's field of view (the area of the ground photographed)
# Output in NAD 83 Zone 12N (EPSG 26912)
wires <- wireFrame(pts, crs = 26912)

# Map
plot(sf::st_geometry(wires))
```

![](README_files/figure-commonmark/unnamed-chunk-3-1.png)

``` r
# Histogram of photo areas
hist(units::set_units(wires$Area, "ha"),
     main = "Histogram of Photo Areas",
     xlab = "Area")
```

![](README_files/figure-commonmark/unnamed-chunk-3-2.png)
