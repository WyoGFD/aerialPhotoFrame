#' Extract camera location (3D point) from photos
#' 
#' Assumes the point is the location of the camera in X, Y, Z.
#'
#' @param dir Character, directory containing photos to process.
#' @param validExt Character vector, only files in \code{dir} that have an
#' extension specified here will be processed.  Exclude the \code{.} (dot) from
#' extensions (e.g., \code{JPG} instead of \code{.JPG})  Use to ignore any
#' non-photo files in \code{dir}. A value of \code{NULL} will read all files.
#' @param crs numeric scalar, EPSG code for coordinate reference system of GPS
#' coordinates in photo metadata.
#'
#' @return sf object of the camera location (X, Y, Z) associated with each 
#' photo. 
#' @export
#'
#' @examples
#' \dontrun{
#' # Create points for camera locations
#' pts <- extractPoints("inst/extdata")
#' names(pts)
#' plot(sf::st_geometry(pts))
#' }

extractPoints <- function(dir,
                          validExt = c("JPG", "jpeg"),
                          crs = 4326) {
  
  # data.frame of photo paths
  # if all files should be read
  if (is.null(validExt)) {
    fileList <- list.files(dir,
                           full.names = TRUE)
  } else {
    # else only files of specified extension(s) should be read
    
    # Remove periods if supplied and collapse into one string
    validExt_collapse <- paste0(gsub("\\.", "", validExt),
                                collapse = "|")
    
    # Construct file pattern to match
    validPattern <- paste0(".*\\.(",
                           validExt_collapse,
                           ")$")
    
    fileList <- list.files(dir,
                           full.names = TRUE,
                           pattern = validPattern,
                           ignore.case = TRUE)
  }
  
  # Check whether there are files to read in
  if (identical(fileList, character(0))) {
    stop("No files in directory that match valid extensions.")
  }
  
  # Check that file names are unique, they are treated as the unique ID
  if (any(duplicated(fileList))) {
    stop("File names must be unique.")
  }
  
  
  # Read exif data
  
  # Faster option is to read only tags (columns) of interest
  # First col will always be SourceFile
  tagsToRead <- c(
    "FileName",
    # "Directory",
    "SubSecCreateDate",
    "ImageWidth",
    "ImageHeight",
    # "ImageBoundary",
    "Megapixels",
    "FocalLength",
    # "MinFocalLength",
    # "MaxFocalLength",
    # "FocalLengthIn35mmFormat",
    # "FocalLength35efl",
    "FOV",
    # "Lens",
    # "LensType",
    # "FocusDistance",
    # "CreateDate",
    "RollAngle",
    "PitchAngle",
    "YawAngle",
    # "GPSPosition",
    "GPSLongitude",
    "GPSLatitude",
    "GPSAltitude"
  )
  
  # Read exif data
  # Move FileName to first col position
  ex <- read_exif(fileList,
                  tags = tagsToRead) |>
    relocate(FileName)
  
  
  # # Slower option to read all tags, then select the tags of interest
  # ex <- read_exif(fileList)
  # 
  # # Keep cols of interest
  # ex <- ex |>
  #   select(c("SourceFile", tagsToRead))
  
  
  # Check that the number of requested tags was returned
  # SourceFile, although not a specified tag, is always the first col returned
  if (ncol(ex) != length(c("SourceFile", tagsToRead))) {
    warning("An unexpected number of exif columns were returned.")
  }
  
  
  # Order by photo timestamp
  # The SubSecCreateDate col has subseconds which are honored by lubridate 
  # even though not printed.
  # And the ending -07:00 must just be the UTC offset for MST?
  # Hard-coding the MST timezone here, would be better to determine from exif
  # (note, there are specific exif cols for time offset)
  ex <- ex |>
    mutate(DateTime = ymd_hms(SubSecCreateDate,
                              tz = "MST")) |>
    arrange(DateTime) |>
    relocate(DateTime, .before = SubSecCreateDate) |>
    select(-SubSecCreateDate)
  
  
  # Make spatial
  pts <- ex |>
    st_as_sf(coords = c("GPSLongitude",
                        "GPSLatitude",
                        "GPSAltitude"),
             dim = "XYZ",
             crs = crs)
  
  # mapview::mapview(st_zm(pts))
  
  
  # Calculate bearing from focal point to next
  # Uses only X and Y dimension, Z ignored
  pts_coords <- st_coordinates(pts)
  pts_bearings <- bearing(pts_coords[, 1:2])
  
  # Recycle last bearing
  pts_bearings[length(pts_bearings)] <- pts_bearings[length(pts_bearings) - 1]
  
  # Add to pts and assign units (degrees)
  pts <- pts |>
    mutate(Bearing = as_units(pts_bearings, "degrees")) |>
    relocate(Bearing, .before = geometry)
  
  return(pts)
  
}