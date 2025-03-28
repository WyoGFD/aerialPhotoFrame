#' Calculate altitude above ground level
#'
#' @param pts sf object of camera locations with Z dimension as altitude of
#' camera above mean sea level in meters.
#' @param res character scalar indicating the resolution of digital elevation 
#' model to use.  Passed to \code{res} argument of \code{FedData::get_ned}.
#' Default is \code{"1"} for 1 arc-second.
#' @param force.redo logical indicating whether the digital elevation model
#' raster should be re-downloaded to the local machine if it already exists.
#' Passed to \code{force.redo} argument of \code{FedData::get_ned}.
#' Default is \code{FALSE}.  If your output has NAs in the \code{elevAGL}
#' column, try setting this to \code{TRUE}.
#'
#' @return sf object, same number of rows as input, with additional columns 
#' indicating the ground elevation (m) and altitude above ground level (AGL) 
#' of the camera (m).
#' @export
#'
#' @examples
#' \dontrun{
#' # Create points for camera locations
#' pts <- extractPoints("inst/extdata")
#' names(pts)
#' plot(sf::st_geometry(pts))
#' 
#' # Add altitude, specifically above-ground-level
#' pts <- calcAltitude(pts)
#' names(pts)
#' hist(pts$elevAGL, xlab = "Camera altitude AGL meters")
#' }

calcAltitude <- function(pts,
                         res = 1,
                         force.redo = FALSE) {
  
  # Error handling - resoluition options for DEM
  if (!res %in% c("1", "13")) {
    stop("Please provide a valid option for res, see FedData::get_ned")
  }
  
  # Project points to same CRS as downloaded DEMs are provided in
  # Saves terra::extract from doing the conversion on the fly and should be
  # faster than projecting the raster
  crs_ned <- 4269
  pts <- sf::st_transform(pts,
                          crs = crs_ned)
  
  
  # Extent of points
  bbox <- sf::st_bbox(pts) |>
    sf::st_as_sfc()
  
  
  # Download DEM for the area
  # See help doc for FedData::get_ned for info on where these rasters are stored
  # on the local machine
  dem <- FedData::get_ned(template = bbox,
                          label = "aerialPhotoFrame",
                          res = res,
                          force.redo = force.redo)
  
  # terra::plot(dem)
  # mapview::mapview(dem) +
  #   mapview::mapview(sf::st_zm(pts))
  
  
  # Extract elevation values at points
  pts <- pts |>
    dplyr::mutate(elevCamera = sf::st_coordinates(pts)[, 3],
                  elevGround = terra::extract(dem,
                                              pts,
                                              raw = TRUE)[, 2],
                  elevAGL = elevCamera - elevGround) |>
    dplyr::relocate(geometry, .after = elevAGL)
  
  
  # Assign units to meters
  pts <- pts |>
    dplyr::mutate(elevCamera = units::as_units(elevCamera, "m"),
                  elevGround = units::as_units(elevGround, "m"),
                  elevAGL = units::as_units(elevAGL, "m"))
  
  
  return(pts)
  
}