"""
Download calibrator stars and save them as a FITS binary table
as required by astrometry.net.

The centres of the observed fields are read from a file objects.csv in
the current directory.
"""

import csv
import subprocess
from astropy import table

import pyvo


CALIB_NAME = "calibrators.fits"


def main():
  with open("objects.csv") as f:
    objects = [(float(r[0]), float(r[1])) for r in csv.reader(f)]
  obj_table = table.Table(
    rows=objects,
    names=('ra', 'dec'))
 
  svc = pyvo.dal.TAPService("http://dc.g-vo.org/tap")
  calibrators = svc.run_async("""
    SELECT
      db.ra, db.dec, phot_g_mean_mag
      FROM gaia.dr3lite AS db
      JOIN TAP_UPLOAD.objs AS tc
      ON 1=CONTAINS(POINT('ICRS', db.ra, db.dec),
                    CIRCLE('ICRS', tc.ra, tc.dec, 40./60.))
    """, uploads={"objs": obj_table},
    maxrec=200000000)
  calibrators.to_table().write(CALIB_NAME,
    format="fits", 
    overwrite=True)

  for preset in range(2, 6):
    subprocess.run([
      "build-astrometry-index",
      "-i", CALIB_NAME, 
      "-o",
      f"index-agns-{preset:02d}.fits",
      "-P", str(preset),
      "-E",
      "-S", "phot_g_mean_mag"])


if __name__=="__main__":
  main()
