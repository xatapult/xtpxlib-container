<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:xtlc="http://www.xtpxlib.nl/ns/common" xmlns:xtlcon="http://www.xtpxlib.nl/ns/container" xmlns:local="#local" exclude-result-prefixes="#all">
  <!-- ================================================================== -->
  <!--*	
    Cleans some paths and other stuff in the zip container.
    Explicitly keep all namespace information (no copy-namespaces="no") to allow copying office stuff.
	-->
  <!-- ================================================================== -->
  <!-- SETUP: -->
  
  <xsl:output method="xml" indent="no" encoding="UTF-8"/>
  
  <xsl:include href="../../../../xtpxlib-common/xslmod/general.mod.xsl"/>
  <xsl:include href="../../../../xtpxlib-common/xslmod/href.mod.xsl"/>
  
  <xsl:param name="add-document-target-paths" as="xs:string" required="yes"/>
  <xsl:param name="href-target-path" as="xs:string" required="yes"/>
  
  <xsl:variable name="do-add-document-target-paths" as="xs:boolean" select="xtlc:str2bln($add-document-target-paths, true())"/>
  
  <!-- ================================================================== -->
  
  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->
  
  <xsl:template match="/*">
    <xsl:copy>
      <xsl:copy-of select="@* except @href-source-zip"/>
      
      <xsl:if test="normalize-space($href-target-path) ne ''">
        <xsl:attribute name="href-target-path" select="$href-target-path"/>
      </xsl:if>
      
      <xsl:attribute name="href-source-zip" select="xtlc:href-protocol-add(xtlc:href-canonical(@href-source-zip), $xtlc:protocol-file, true())"/>
      
      <xsl:apply-templates/>
      
    </xsl:copy>
  </xsl:template>
  
  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->
  
  <xsl:template match="xtlcon:*[exists(@href-source)]">
    <xsl:copy>
      <xsl:copy-of select="@* except @href-source"/>
      
      <xsl:variable name="href-source-raw" as="xs:string" select="@href-source"/>
      <xsl:variable name="href-source" as="xs:string"
        select="if (starts-with($href-source-raw, '/')) then substring($href-source-raw, 2) else $href-source-raw"/>
      
      <xsl:attribute name="href-source" select="$href-source"/>
      
      <xsl:if test="$do-add-document-target-paths">
        <xsl:attribute name="href-target" select="$href-source"/>
      </xsl:if>
      
      <xsl:apply-templates/>
      
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>
