
from gavo import api

class MyProcessor(api.AnetHeaderProcessor):
  indexPath = "/usr/share/astrometry"
  sp_indices = ["index-*.fits"],
  sp_lower_pix = 0.1
  sp_upper_pix = 0.2
  sp_endob = 50

  sourceExtractorControl = """
  DETECT_MINAREA   20
  DETECT_THRESH    6
  SEEING_FWHM      1.2
  """
  


  def _mungeHeader(self, srcName, hdr):
    vals = {
      "OBJTYP": "AGN"
      }
    return fitstricks.makeHeaderFromTemplate(
       fitstricks.WFPDB_TEMPLATE,
       originalHeader=hdr, **vals)
