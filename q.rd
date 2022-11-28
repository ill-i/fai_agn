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

  <meta name="source">%ideally, a bibcode%</meta>
  <meta name="contentLevel">Research</meta>
  <meta name="type">Catalog</meta>  <!-- or Archive, Survey, Simulation -->

  <!-- Waveband is of Radio, Millimeter, 
      Infrared, Optical, UV, EUV, X-ray, Gamma-ray, can be repeated -->
  <meta name="coverage.waveband">Optical</meta>

  <table id="main" onDisk="True" mixin="//siap#pgs" adql="True">

    <!-- in the following, just delete any attribute you don't want to
    set.
    
    Get the target class, if any, from 
    http://simbad.u-strasbg.fr/guide/chF.htx -->
    <!-- <mixin
      calibLevel="2"
      collectionName="'%a few letters identifying this data%'"
      targetName="%column name of an object designation%"
      expTime="%column name of an exposure time%"
      targetClass="'%simbad target class%'"
    >//obscore#publishSIAP</mixin> -->

		<column name="objects" type="char(15)[]"
			ucd="meta.id;src"
			tablehead="Objs."
			description="Names of objects"
			verbLevel="3"/>	
		<column name="target_ra"
			unit="deg" ucd="pos.eq.ra;meta.main"
			tablehead="Target RA"
			description="Right ascension of object from observation log."
			verbLevel="1"/>
		<column name="target_dec"
			unit="deg" ucd="pos.eq.dec;meta.main"
		  tablehead="Target Dec"
			description="Declination of object from observation log."
			verbLevel="1"/>
		<column name="exptime"
		  unit="s" ucd="time.duration;obs.exposure"
		  tablehead="T.Exp"
		  description="Exposure time from observation log."
		  verbLevel="5"/>
		<column name="telescope" type="text"
		   ucd="instr.tel"
		   tablehead="Telescope"
		   description="Telescope from observation log."
		   verbLevel="3"/>

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
					telescope: TELESCOP
				</simplemaps>
        <!-- put vars here to pre-process FITS keys that you need to
          re-format in non-trivial ways. -->
        <apply procDef="//siap#setMeta">
          <!-- DaCHS can deal with some time formats; otherwise, you
            may want to use parseTimestamp(@DATE_OBS, '%Y %m %d...') -->
          <bind key="dateObs">@DATE-OBS</bind>

          <!-- bandpassId should be one of the keys from
            dachs adm dumpDF data/filters.txt;
            perhaps use //procs#dictMap for clean data from the header. -->
          <bind key="bandpassId">@FILTER</bind>

          <!-- pixflags is one of: C atlas image or cutout, F resampled, 
            X computed without interpolation, Z pixel flux calibrated, 
            V unspecified visualisation for presentation only
          <bind key="pixflags"></bind> -->
          
          <!-- titles are what users usually see in a selection, so
            try to combine band, dateObs, object..., like
            "MyData {} {} {}".format(@DATE_OBS, @TARGET, @FILTER) -->
          <bind key="title">"{} {} {}".format(@OBJECT, @DATE_OBS, @FILTER)</bind>
        </apply>

        <apply procDef="//siap#getBandFromFilter"/>

        <apply procDef="//siap#computePGS"/>

				<map key="target_ra">hmsToDeg(@OBJCTRA, sepChar=" ")</map>
				<map key="target_dec">dmsToDeg(@OBJCTDEC, sepChar=" ")</map>
				<map key="observer" source="OBSERVER" nullExcs="KeyError"/>
				<map key="objects">@mapped_names.split("|")</map>

        <!-- any custom columns need to be mapped here; do *not* use
          idmaps="*" with SIAP -->
      </rowmaker>
    </make>
  </data>

	<dbCore queriedTable="main" id="imagecore">
    <condDesc original="//siap#protoInput"/>
	  <condDesc original="//siap#humanInput"/>
	  <condDesc buildFrom="dateObs"/>
	  <condDesc>
		  <inputKey name="object" type="text" multiplicity="multiple"
				  tablehead="Target Object"
				  description="Object being observed, Simbad-resolvable form"
				  ucd="meta.name">
					<values fromdb="unnest(objects) FROM fai50mak.main"/>
			</inputKey>
			<phraseMaker>
				<setup imports="numpy"/>
				<code><![CDATA[
					yield "%({})s && objects".format(
						base.getSQLKey("object",
						numpy.array(inPars["object"]), outPars))
				]]></code>
			</phraseMaker>
		</condDesc>
	</dbCore>

  <!-- if you want to build an attractive form-based service from
    SIAP, you probably want to have a custom form service; for
    just basic functionality, this should do, however. -->
  <service id="web" allowed="form" core="imagecore">
    <meta name="shortName">fai_agn siap</meta>
		<meta name="title">Web interface to FAI AGN observations</meta>
		<outputTable autoCols="accref,accsize,centerAlpha,centerDelta,
		        dateObs,imageTitle">
			<outputField original="objects">
				<formatter>
					return " - ".join(data)
				</formatter>
			</outputField>
		</outputTable>
	</service>
    <!-- other sia.types: Cutout, Mosaic, Atlas -->

  <service id="web" allowed="form,siap.xml" core="imagecore">
    <meta name="shortName">fai_agn siap</meta>
		<meta name="sia.type">Pointed</meta>
    
    <meta name="testQuery.pos.ra">345.8</meta>
    <meta name="testQuery.pos.dec">8.9</meta>
    <meta name="testQuery.size.ra">0.1</meta>
    <meta name="testQuery.size.dec">0.1</meta>

    <!-- this is the VO publication -->
    <publish render="siap.xml" sets="ivo_managed"/>
    <!-- this puts the service on the root page -->
    <publish render="form" sets="local,ivo_managed"/>
    <!-- all publish elements only become active after you run -->
  </service>

  <regSuite title="fai_agn regression">

    <regTest title="fai_agn SIAP serves some data">
      <url POS="345.8,8.9" SIZE="0.1,0.1"
        >i/siap.xml</url>
      <code>
        rows = self.getVOTableRows()
				self.assertEqual(len(rows), 1)
				row = rows[0]
				self.assertEqual(row["objects"][0].strip(), "NGC7469")
				self.assertEqual(len(row["objects"]), 1)
				self.assertEqual(row["imageTitle"],
								'NGC7469-007_R.fit.fit')
			</code>
    </regTest>

  </regSuite>
</resource>
