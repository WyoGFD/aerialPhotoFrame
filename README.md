# aerialPhotoFrame
Identify the ground extent (AKA wireframe) of a photo taken from the air, and
create a spatial (sf) object.  Useful in calculating area sampled in aerial photos
and approximate spatial location. Should be applicable for photos taken from airplane or drone.

## Inputs
+ Photo metadata - namely the coordinates (X, Y, Z) of the camera when the photo was taken, and the photo timestamp.
+ Camera info - probably field of view, dimensions of sensor?



## Function ideas
+ calcAlt - use FedData to get local DEM (maybe for whole study area), calculate approximate altitude above ground level from camera's altitude above mean sea level and DEM.
+ calcDir - use sequence (timestamps) of photos to determine the direction of travel and therefore the orientation of the photo
+ createFrame - use nominal image dimensions (for angle of view?), altitude, and direction of travel to construct rectangular wireframe of photo's ground extent

