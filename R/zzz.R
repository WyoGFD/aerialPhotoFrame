.onAttach <- function(libname, pkgname) {
  
  # Pull package version number
  v <- packageVersion("aerialPhotoFrame")
  
  # Print as startup message
  packageStartupMessage(paste0("aerialPhotoFrame (version ",
                               v,
                               ")"))
}