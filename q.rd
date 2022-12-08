<resource schema="fai_agn" resdir=".">
  <meta name="creationDate">2022-11-28T09:25:45Z</meta>

  <meta name="title">AGN observations obtained at FAI</meta>
  <meta name="description">
  The database of Active Galactic Nuclea (AGN) photometrical observations obtained on defferent telescopes at Fesenkov Astrophysical Institute, Almaty, Kazakhstan since 2016. Observations were carried out in the optical range.
  </meta>
  <!-- Take keywords from 
    http://www.ivoa.net/rdf/uat
    if at all possible -->
  <meta name="subject">active-galactic-nuclei</meta>
  <meta name="subject">active-galaxies</meta>

  <meta name="creator">Fesenkov Astrophysical Institute</meta>
  <meta name="instrument">AZT-8</meta>
  <meta name="instrument">Zeiss-1000</meta>
  <meta name="facility">Fesenkov Astrophysical Institute</meta>
  <meta name="facility">Tian Shan Astronomical Observatory</meta>

  <meta name="contentLevel">Research</meta>
  <meta name="type">Catalog</meta>  <!-- or Archive, Survey, Simulation -->

  <!-- Waveband is of Radio, Millimeter, 
      Infrared, Optical, UV, EUV, X-ray, Gamma-ray, can be repeated -->
  <meta name="coverage.waveband">Optical</meta>

  <table id="main" onDisk="True" mixin="//siap#pgs" adql="True">

    <meta name="_associatedDatalinkService">
      <meta name="serviceId">dl</meta>
      <meta name="idColumn">pub_did</meta>
    </meta>

    <mixin
      calibLevel="2"
      collectionName="'FAI AGN Phot'"
      targetName="OBJECT"
      expTime="EXPTIME"
      target_class="'AGN'"
    >//obscore#publishSIAP</mixin>

    <column name="object" type="text"
      ucd="meta.id;src"
      tablehead="Obj."
      description="Object name"
      verbLevel="3"/>  
    <column name="target_ra"
      unit="deg" ucd="pos.eq.ra;meta.main"
      tablehead="Target RA"
      description="Right ascension of an object."
      verbLevel="1"/>
    <column name="target_dec"
      unit="deg" ucd="pos.eq.dec;meta.main"
      tablehead="Target Dec"
      description="Declination of an object."
      verbLevel="1"/>
    <column name="exptime"
      unit="s" ucd="time.duration;obs.exposure"
      tablehead="T.Exp"
      description="Exposure time."
      verbLevel="5"/>
    <column name="telescope" type="text"
      ucd="instr.tel"
      tablehead="Telescope"
      description="Telescope."
      verbLevel="3"/>
    <column name="observat" type="text"
      ucd="meta.id;instr.obsty"
      tablehead="Observat"
      description="Observatory where data was obtained."
      verbLevel="3"/>
    <column name="readoutm" type="text"
      ucd="meta.note"
      tablehead="RedaoutMode"
      description="Readout mode of image"
      verbLevel="3"/>
    <column name="bin" type="integer" required="True"
      ucd="meta.number;instr.pixel"
      tablehead="Binning"
      description="Binning factor"
      verbLevel="3"/>
    <column name="airmass" type="real"
      ucd="obs.airMass" 
      tablehead="Airmass"
      description="Relative optical path length through atmosphere"
      verbLevel="3"/>
    <column name="pub_did" type="text"
      ucd="meta.ref.ivoid"
      tablehead="pubDID"
      description="publisherDID of this dataset"
      verbLevel="4"/>
  </table>

  <coverage>
    <updater sourceTable="main"/>
  </coverage>

  <!-- if you have data that is continually added to, consider using
    updating="True" and an ignorePattern here; see also howDoI.html,
    incremental updating -->
  <data id="import">
    <sources pattern="data/*.fit"/>

    <!-- the fitsProdGrammar should do it for whenever you have
    halfway usable FITS files.  If they're not halfway usable,
    consider running a processor to fix them first – you'll hand
    them out to users, and when DaCHS can't deal with them, chances
    are their clients can't either -->
    <fitsProdGrammar>
      <rowfilter procDef="//products#define">
        <bind key="table">"\schema.main"</bind>
      </rowfilter>
    </fitsProdGrammar>

    <make table="main">
      <rowmaker>
        <simplemaps>
          exptime: EXPOSURE,
          telescope: TELESCOP,
          readoutm:READOUTM,
          bin:XBINNING,
          airmass:AIRMASS
        </simplemaps>

        <apply procDef="//procs#dictMap">
        <bind key="mapping">{
            "B_Johnson": "Johnson B",
            "V_Johnson": "Johnson V",
            "R_Johnson": "Johnson R",
            "CLEAR": "Cear",
            "Sloan_u": "SDSS u",
            "Sloan_g": "SDSS g",
            "Sloan_r": "SDSS r",
            "Sloan_i": "SDSS i",
            "Sloan_z": "SDSS z",
           }</bind>
          <bind key="key">"FILTER"</bind>
        </apply>

        <!-- put vars here to pre-process FITS keys that you need to
          re-format in non-trivial ways. -->
        <apply procDef="//siap#setMeta">
          <!-- DaCHS can deal with some time formats; otherwise, you
            may want to use parseTimestamp(@DATE_OBS, '%Y %m %d...') -->
          <bind key="dateObs">@DATE_OBS</bind>

          <!-- bandpassId should be one of the keys from
            dachs adm dumpDF data/filters.txt;
            perhaps use //procs#dictMap for clean data from the header. -->
          <bind key="bandpassId">@FILTER</bind>

          <!-- pixflags is one of: C atlas image or cutout, F resampled, 
           without interpolation, Z pixel flux calibrated, 
            V unspecified visualisation for presentation only
          <bind key="pixflags"></bind> -->
          
          <bind key="title">"{} {} {}".format(@OBJECT, @DATE_OBS, @FILTER)</bind>
        </apply>

        <apply procDef="//siap#getBandFromFilter"/>

        <apply procDef="//siap#computePGS"/>

        <map key="target_ra">hmsToDeg(@OBJCTRA, sepChar=" ")</map>
        <map key="target_dec">dmsToDeg(@OBJCTDEC, sepChar=" ")</map>
        <map key="object">@OBJECT</map>
        <map key="observat">vars.get("OBSERVAT")</map>
        <map key="pub_did">\standardPubDID</map>

        <!-- any custom columns need to be mapped here; do *not* use
          idmaps="*" with SIAP -->
      </rowmaker>
    </make>
  </data>



  <service id="dl" allowed="dlmeta,static">
    <meta name="title">FAI AGN raw image datalink</meta>
    <property key="staticData">../calib_frames</property>

    <datalinkCore>
      <descriptorGenerator procDef="//soda#fromStandardPubDID"/>
      <metaMaker semantics="#calibration">
        <setup imports="pathlib, astropy.time, gavo.utils.fitstools">
          <par name="bandMapping">{
              "B_Johnson": "B",
              "R_Johnson": "R",
              "V_Johnson": "V",
              "CLEAR": "CL",
              "Sloan_u": "SDSS u",
               "Sloan_g": "SDSS g",
              "Sloan_r": "SDSS r",
              "Sloan_i": "SDSS i",
              "Sloan_z": "SDSS z"
            }</par>
          <par name="telescopeMapping">{
              "AZT-20": "azt_20",
              "Zeiss-1000 (East)": "zeiss_1000_east",
              "Zeiss-1000 (West)": "zeiss_1000_west",
              "AZT-8": "azt_8",
              "": "UNKNOWN",
            }</par>

          <code><![CDATA[
            def get_closest_files(directory, ctype, time_jd, exptime, filt, binning):
              """
              returns the path of the files in directory with the closest timestamp.
              """
              files = []
              directory = pathlib.Path(directory)
              CALFILE_NAMES = {"Flat":f"Flat_*_{filt}_{binning}.fit",
                "Dark":f"Dark_*_{exptime}_{binning}.fit",
                "Bias":f"Bias_*_{binning}.fit"}

              for name in directory.glob(CALFILE_NAMES.get(ctype)):
                #get absolute path with names of files 
                try:
                  date_lit = name.split("_")[1]
                  if len(date_lit)<8: 
                    date_lit = "20"+date_lit 
                  iso_date_lit = f'{date_lit[:4]}-{date_lit[4:6]}-{date_lit[6:]}'
                  files.append(
                    (abs(time.Time(iso_date_lit, format="isot").jd
                        -float(time_jd)),
                    name))
                except IOError: # don't worry about disappearing files
                  pass

                files.sort()
                minmimal_offset = files[0][0]
                calib_files = []
                for f in files:
                  if abs(f[0]-minimal_offset)<0.5:
                    calib_files.append(f[1])
                else:
                  return calib_files
              raise IOError("No calibration frame for"
                f" {time.Time(time_jd).iso[:10]}, {filt} and {binning}")
          ]]></code>
        </setup>

        <code>
          # common setup for all meta makes
          with open(os.path.join(
              base.getConfig("inputsDir"),
              descriptor.accessPath), "rb") as f:
            descriptor.fits_header = fitstools.readPrimaryHeaderQuick(f)
          telescope = telescopeMapping[descriptor.fits_header["TELESCOP"]]
          descriptor.calib_path = os.path.join(
            base.getConfig("inputsDir"), f"fai_calib_frames/data/{telescope}")
          descriptor.static_service = base.resolveCrossId(
                "fai_calib_frames/q#deliver")

          # make the #flat link
          for flat_path in get_closest_files(descriptor.calib_path, "Flat", 
              descriptor.fits_header["JD"], 
              None,
              bandMapping[descriptor.fits_header["FILTER"]],
              descriptor.fits_header["XBINNING"]):
            yield descriptor.makeLinkFromFile(
              flat_path, semantics="#flat",
              description="CCD Flat to be used for this frame based on date, binning and filter."
                "  Use some linear combination of these if you get multiple flats.")

          # TODO: Same for #bias

          for bias_path in get_closest_files(descriptor.calib_path, "Bias", 
              descriptor.fits_header["JD"], 
              None,
              None,
              descriptor.fits_header["XBINNING"]):
            yield descriptor.makeLinkFromFile(
              bias_path, semantics="#bias",
              description="CCD Bias to be used for this frame based on date and binning."
                "  Use some linear combination of these if you get multiple bias.")
          # TODO: Same for #dark
          for dark_path in get_closest_files(descriptor.calib_path, "Dark", 
              descriptor.fits_header["JD"], 
              descriptor.fits_header["EXPOSURE"], 
              None,
              descriptor.fits_header["XBINNING"]):
            yield descriptor.makeLinkFromFile(
              dark_path, semantics="#dark",
              description="CCD Dark to be used for this frame based on date, exposure and binning."
                "  Use some linear combination of these if you get multiple flats.")
        </code>
      </metaMaker>
      
    </datalinkCore>

  </service>


  <dbCore queriedTable="main" id="imagecore">
    <condDesc original="//siap#protoInput"/>
    <condDesc original="//siap#humanInput"/>
    <condDesc buildFrom="dateObs"/>
    <condDesc buildFrom="object"/>
  </dbCore>

  <service id="web" allowed="form" core="imagecore">
    <meta name="shortName">fai_agn web</meta>
    <meta name="title">Web interface to FAI AGN observations</meta>
    <outputTable autoCols="accref,accsize,centerAlpha,centerDelta,
            dateObs,imageTitle,object">
      <outputField original="pub_did" tablehead="Datalink">
        <formatter>
          return T.a(href="/fai_agn/q/dl/dlmeta?ID="
            +urllib.parse.quote(data))["datalink"]
        </formatter>
      </outputField>
    </outputTable>
  </service>
    <!-- other sia.types: Cutout, Mosaic, Atlas -->

  <service id="i" allowed="siap.xml" core="imagecore">
    <meta name="shortName">fai_agn siap</meta>
    <meta name="sia.type">Pointed</meta>
    
    <meta name="testQuery.pos.ra">345.8</meta>
    <meta name="testQuery.pos.dec">8.9</meta>
    <meta name="testQuery.size.ra">0.1</meta>
    <meta name="testQuery.size.dec">0.1</meta>

    <!-- this is the VO publication -->
    <publish render="siap.xml" sets="ivo_managed"/>
    <!-- this puts the service on the root page -->
    <publish render="form" sets="local,ivo_managed" service="web"/>
    <!-- all publish elements only become active after you run -->
  </service>

  <regSuite title="fai_agn regression">

    <regTest title="fai_agn SIAP serves some data">
      <url POS="345.8,8.9" SIZE="0.1,0.1" dateObs="57635.8214/"
        >i/siap.xml</url>
      <code>
        rows = self.getVOTableRows()
        self.assertEqual(len(rows), 1, "There is just one match")
        row = rows[0]
        self.assertEqual(row["object"], "NGC7469")
        self.assertEqual(row["imageTitle"],
                'NGC7469 2016-09-04T19:42:52.51 Johnson R')
      </code>
    </regTest>

    <regTest title="fai_agn datalink looks plausible">
      <url
        ID="ivo://fai.kz/~?fai_agn/data/NGC7469-007_R.fit"
        >dl/dlmeta</url>
      <code>
        rows = self.getVOTableRows()
        bySemantics = dict((r["semantics"], r) for r in rows)

        self.assertTrue(bySemantics["#this"]["access_url"].endswith(
          "getproduct/fai_agn/data/NGC7469-007_R.fit"),
          "#this URI is wrong")
        self.assertEqual(bySemantics["#this"]["content_length"], 4682880)

      </code>
    </regTest>
  </regSuite>
</resource>
