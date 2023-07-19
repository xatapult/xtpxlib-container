<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions"
  xmlns:xtlc="http://www.xtpxlib.nl/ns/common" xmlns:xtlcon="http://www.xtpxlib.nl/ns/container"
  xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:local="#local" exclude-result-prefixes="#all">
  <!-- ================================================================== -->
  <!--~	
    Decodes the names of the files (removes the % encodings).
	-->
  <!-- ================================================================== -->
  <!-- SETUP: -->

  <xsl:output method="xml" indent="no" encoding="UTF-8"/>

  <xsl:include href="../../../../xtpxlib-common/xslmod/href.mod.xsl"/>

  <!-- ================================================================== -->

  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="c:entry/@name"> 
    <xsl:attribute name="{fn:local-name(.)}" select="xtlc:href-decode-uri(.)"/>
  </xsl:template>

</xsl:stylesheet>
