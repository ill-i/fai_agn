"""
This is a DaCHS processor (http://docs.g-vo.org/DaCHS/processors.html)
to calibrate FITS files containing modern AGN observations obtained on different telescopes of Fesenkov Astrophysical Institute.
"""
import os
from gavo.helpers import fitstricks
from gavo import api

from gavo.helpers import anet


class PAHeaderAdder(api.AnetHeaderProcessor):
  indexPath = os.path.join(api.getConfig("inputsDir"), 
  	"fai_agn", "customindex")
  sp_total_timelimit = 120
  sp_endob = 200
  sp_indices = ["index-agns*.fits"]

  sourceExtractorControl = """
    DETECT_MINAREA   20
    DETECT_THRESH    3
    SEEING_FWHM      1.2
  """

  def NOobjectFilter(self, inName):
    """throws out funny-looking objects from inName as well as objects
    near the border.
    """
    hdulist = api.pyfits.open(inName)
    data = hdulist[1].data
    width = max(data.field("X_IMAGE"))
    height = max(data.field("Y_IMAGE"))
    badBorder = 0.2
    data = data[data.field("ELONGATION")<1.2]
    data = data[data.field("X_IMAGE")>width*badBorder]
    data = data[data.field("X_IMAGE")<width-width*badBorder]
    data = data[data.field("Y_IMAGE")>height*badBorder]
    data = data[data.field("Y_IMAGE")<height-height*badBorder]

    # the extra numpy.array below works around a bug in several versions
    # of pyfits that would write the full, not the filtered array
    hdu = api.pyfits.BinTableHDU(numpy.array(data))
    hdu.writeto("foo.xyls")
    hdulist.close()
    os.rename("foo.xyls", inName)

  def _shouldRunAnet(self, srcName, header):
    return True

  def _isProcessed(self, srcName):
# TODO: make the thing actually sense whether a new-style header is present
    return os.path.exists(srcName+".hdr")

  def _mungeHeader(self, srcName, hdr):
    return fitstricks.makeHeaderFromTemplate(
            fitstricks.MINIMAL_IMAGE_TEMPLATE,
            originalHeader=hdr, 
            OBJTYP="AGN")

if __name__=="__main__":
  api.procmain(PAHeaderAdder, "fai_agn/q", "import")
