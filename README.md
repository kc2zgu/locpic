LocPic - the Location tagger for digital Pictures
=================================================

Introduction
------------

LocPic is a program for geotagging digital photos based on GPS track
data. It is designed to work efficiently with large datasets, such as
many years' worth of track logs and collections of hundreds of images
taken by multiple cameras.

GPS Tracks
----------

GPS track logs in GPX format are supported and can be loaded into a
SQLite database for fast access. The locpic-track.pl script loads GPX
files into this database so they can be used for tagging later.

Camera and GPS Time
-------------------

In order to geotag a photo, a GPS fix close to the time it was taken
needs to be found. The image timestamp is used, but an offset can be
applied to correct for any small difference between the camera's clock
and GPS time (many cameras only allow setting the clock to 1 minute
resolution, which can introduce significant errors).

To calculate the camera's time offset, set the clock as close as
possible to GPS time, then take a picture of the GPS screen showing
the clock (or another clock synchronized to GPS/UTC). The
locpic-align.pl script will read the camera's timestamp from this
image, compare it to the GPS time entered on the command line, and
calculate the difference between the two clocks.

Time Zone Handling
------------------

When synchronizing camera and GPS clocks, time zones need to be
considered. GPS tracks always recurd UTC time but camera clocks and
GPS clock displays may or may not be in local time. locpic-align.pl
takes an argument that sets the local time zone offset. It can also
detect the time zone used by the camera (certain Canon cameras are
currently supported) to automatically translate camera timestamps to
UTC.

Tagging Photos
--------------

Once GPS tracks and a clock offset are available, the locpic-tag.pl
script can be run to calculate location tags for one or more images
and optionally write them to the image files.

Future Features
---------------

 * Store clock offsets history in a database for automatic lookup
 * Interpolate/extrapolate camera clock drift
 * Time zone map to guess the local time zone based on GPS location
 * More options for controlling track matching, interpolation, and
   resolving multiple track matches
 * Heuristics to guess clock offset based on track statistics
   (partially implemented)

