#' Create wireframe of photo footprints
#'
#' @param pts sf object of camera locations with column indicating the camera's
#' altitude above ground level (m).  Output from \code{calcAltitude}.
#' @param crs numeric scalar, EPSG code for coordinate reference system to use 
#' for planar calculations and for output wireframes.
#'
#' @return sf object (POLYGON) of ground area photographed for each photo,
#' includes same data columns as input \code{pts}, has projection specified by
#' input \code{crs}.
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
#' 
#' # Create wireframe of each photo's field of view
#' # AKA the area of the ground photographed
#' wires <- wireFrame(pts, crs = 26912)
#' plot(sf::st_geometry(wires))
#' plot(sf::st_geometry(pts), col = "black", add = TRUE)
#' }

wireFrame <- function(pts, 
                      crs = 26912) {
  
  # Check that filenames are unique, they are treated as the unique ID
  if (any(duplicated(pts$FileName))) {
    stop("Filenames must be unique.")
  }
  
  
  # Strip Z dimension from points and project to desired CRS
  pts <- sf::st_zm(pts) |>
    sf::st_transform(crs = crs)
  
  # Check whether the units of the CRS are meters
  # The crs_ud_units function isn't exported from sf, hence the triple colon :::
  if (!identical(sf:::crs_ud_unit(sf::st_crs(pts)),
                units::as_units(1, "m"))) {
    stop("The specified crs must have units of meters.")
  }
  
  
  # Make aspatial to do math on coordinates to make rectangular wireframe from
  # points
  # Keep filename as primary key
  # and only those cols needed to create the proper wireframe dimensions
  pts_df <- cbind(sf::st_drop_geometry(pts),
                  sf::st_coordinates(pts)) |>
    dplyr::select(FileName,
                  ImageHeight,
                  ImageWidth,
                  FOV,
                  elevAGL,
                  X,
                  Y)
  
  
  # Use camera specs (focal length and image sensor size) and altitude AGL to
  # estimate the field of view of each photo independently.  That way the
  # wireframe can be made to the right size (no later scaling needed) with only
  # rotation needed later
  
  # Examples at https://geekingoutwithdave.com/lens-coverage/
  
  # # Can calculate field of view (AKA angle of view) from sensor size and lens
  # # focal length, but FOV happens to be stored in exif, so trust that instead
  # # https://en.wikipedia.org/wiki/Angle_of_view_(photography)
  # sensorWidth <- 36  # mm
  # focalLength <- 50  # mm
  # (a <- 2 * atan(sensorWidth / (2 * focalLength)))
  # (a <- units::as_units(a, "radians"))
  # (a <- units::set_units(a, "degrees"))
  
  # Extract the field of view from exif data (first part of FOV col)
  pts_df <- pts_df |>
    mutate(fov = units::as_units(as.numeric(gsub(" .*", "", FOV)),
                                 "degrees"),
           fov_half = fov / 2)
  
  
  # Calculate ground dimensions (half width and half height) of each photo
  # based on right-triangle trigonometry and exif-stored photo aspect ratio
  pts_df <- pts_df |>
    mutate(w_half = sqrt((elevAGL / cos(fov_half))^2 - elevAGL^2),
           h_half = w_half * (ImageHeight / ImageWidth),
           area = 2 * w_half * 2 * h_half)
  
  
  # Make wireframe of appropriate dimensions and nominal north-up orientation
  # Start by calculating coordinates of each corner vertex from centroid
  # sf needs one vertex recycled to close polygon - using top-left here
  wires <- pts_df |>
    mutate(X = units::as_units(X, "m"),
           Y = units::as_units(Y, "m"),
           X_TL1 = X - w_half,
           X_TR = X + w_half,
           X_BR = X + w_half,
           X_BL = X - w_half,
           Y_TL1 = Y + h_half,
           Y_TR = Y + h_half,
           Y_BR = Y - h_half,
           Y_BL = Y - h_half,
           X_TL2 = X_TL1,
           Y_TL2 = Y_TL1)
  
  
  # Reshape to have X, Y pair for each corner of the frame (plus one recycled
  # to close shape)
  wires <- wires |>
    dplyr::select(FileName,
                  X_TL1:Y_TL2) |>
    tidyr::pivot_longer(-FileName) |>
    tidyr::separate_wider_delim(name,
                                delim = "_",
                                names = c("dimension", "corner")) |>
    tidyr::pivot_wider(names_from = dimension,
                       values_from = value)
  
  # Make spatial
  # https://stackoverflow.com/questions/52669779/convert-sets-of-spatial-coordinates-to-polygons-in-r-using-sf
  wires <- wires |>
    sf::st_as_sf(coords = c("X", "Y"),
                 crs = crs) |>
    dplyr::group_by(FileName) |>
    dplyr::summarize(geometry = sf::st_combine(geometry)) |>
    sf::st_cast("POLYGON")
  
  # # Plot
  # plot(sf::st_geometry(wires))
  # plot(sf::st_geometry(pts), col = "black", add = TRUE)
  # 
  # mapview::mapview(wires) +
  #   mapview::mapview(pts)
  

  
  # Rotate using affine transformation
  # Could also scale larger or smaller using same, but opted to construct to
  # correct diemsions first than rescale later
  scaleFactor <- 1
  
  # Convert rotation degrees (from N) from degrees to radians
  bearingRadians <- units::set_units(pts$Bearing, "radians")
  
  
  # Function to rotate
  # https://r-spatial.github.io/sf/articles/sf3.html#affine-transformations
  # param a is scalar radians
  rot <- function(a) {
    matrix(c(cos(a),
             sin(a),
             -sin(a),
             cos(a)),
           nrow = 2,
           ncol = 2)
  }
  
  # Requires sfc rather than sf objects for transformation math operations
  
  # sfc of wires
  wires_sfc <- wires |>
    sf::st_geometry(wires)
  
  # sfc of points to rotate around (using wire centroids) 
  pts_sfc <- wires_sfc |>
    sf::st_centroid()
  
  
  # Apply transformation photo by photo
  wires_rot_sfc <- do.call(rbind, lapply(1:length(wires_sfc), function(i){
    (wires_sfc[i] - pts_sfc[i]) * rot(bearingRadians[i]) * scaleFactor + pts_sfc[i]
  }))
  

  # Make sf object with primary key added back to data.frame
  wires_rot <- wires_rot_sfc |>
    sf::st_sf(FileName = wires$FileName,
              crs = sf::st_crs(wires))
  

  # plot(sf::st_geometry(wires_rot))
  # plot(sf::st_geometry(pts), col = "black", add = TRUE)
  # 
  # mapview::mapview(wires_rot) +
  #   mapview::mapview(pts)
  
  
  # Join back the cols present in input data
  pts_toJoin <- sf::st_drop_geometry(pts)
  
  wires_out <- wires_rot |>
    dplyr::left_join(pts_toJoin,
                     by = "FileName")
  
  # Set name of geometry col to sf standard "geometry"
  names(wires_out)[ncol(wires_out)] <- "geometry"
  sf::st_geometry(wires_out) <- "geometry"
  
  # plot(sf::st_geometry(wires_out))
  # plot(sf::st_geometry(pts), col = "black", add = TRUE)

  
return(wires_out)

  
}