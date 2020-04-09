<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:xtlc="http://www.xtpxlib.nl/ns/common"
  xmlns:xtlcon="http://www.xtpxlib.nl/ns/container" xmlns:local="#local" exclude-result-prefixes="#all">
  <!-- ================================================================== -->
  <!--~	
    Computes the actual paths the container and files must be written to or read from.	
	-->
  <!-- ================================================================== -->
  <!-- SETUP: -->

  <xsl:output method="xml" indent="no" encoding="UTF-8"/>

  <xsl:include href="../../../../xtpxlib-common/xslmod/general.mod.xsl"/>
  <xsl:include href="../../../../xtpxlib-common/xslmod/href.mod.xsl"/>

  <xsl:param name="href-target" as="xs:string" required="yes"/>

  <xsl:variable name="base-result-path" as="xs:string"
    select="local:href-normalize(if (normalize-space($href-target) ne '') then $href-target else string(/*/@href-target-path))"/>
  
  <xsl:variable name="base-source-path" as="xs:string" select="local:href-normalize((/*/@href-source-path, base-uri(/*))[1])"/>  

  <xsl:variable name="main-source-zip" as="xs:string?" select="/*/@href-source-zip"/>
  <xsl:variable name="href-global-zip" as="xs:string"
    select="if (normalize-space($main-source-zip) ne '') then local:href-normalize(resolve-uri($main-source-zip, base-uri(/*))) else ''"/>

  <!-- ================================================================== -->

  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- CHANGES ON ROOT: -->

  <xsl:template match="/*">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>

      <!-- Record the base result path on the root element. Make sure we record it with a single trailing /: -->
      <xsl:if test="normalize-space($base-result-path) eq ''">
        <xsl:call-template name="xtlc:raise-error">
          <xsl:with-param name="msg-parts" select="'container-to-disk: No target path specified'"/>
        </xsl:call-template>
      </xsl:if>
      <xsl:attribute name="href-target-result-path" select="concat(replace($base-result-path, '/+$', ''), '/')"/>

      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="/*/@href-source-zip">
    <xsl:choose>
      <xsl:when test="normalize-space(.) ne ''">
        <xsl:attribute name="{name(.)}" select="$href-global-zip"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- Empty attribute, remove. -->
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- CHANGES ON DOCUMENTS: -->

  <xsl:template match="/*/xtlcon:document[normalize-space(@href-target) ne ''] | /*/xtlcon:external-document[normalize-space(@href-target) ne '']">
    <xsl:copy>
      <xsl:apply-templates select="@* except (@href-source-result, @href-target-result, @href-source-zip-result)"/>

      <!-- Set the result dref: -->
      <xsl:attribute name="href-target-result" select="xtlc:href-add-encoding(local:href-normalize(xtlc:href-concat(($base-result-path, @href-target))))"/>

      <!--For external documents, we need to compute some more stuff: -->
      <xsl:if test="self::xtlcon:external-document">
        <xsl:variable name="not-in-global-source-zip" as="xs:boolean" select="xtlc:str2bln(@not-in-global-source-zip, false())"/>

        <!-- Zip reference -->
        <xsl:variable name="href-zip" as="xs:string?">
          <xsl:choose>
            <!-- When this entry has a source zip file, normalize it: -->
            <xsl:when test="normalize-space(@href-source-zip) ne ''">
              <xsl:sequence select="local:href-normalize(resolve-uri(@href-source-zip, base-uri(/*)))"/>
            </xsl:when>
            <!-- When there is a global zip file, use this (unless it is specifically marked as not-in-global-source-zip):  -->
            <xsl:when test="(normalize-space($href-global-zip) ne '') and not($not-in-global-source-zip)">
              <xsl:sequence select="$href-global-zip"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:sequence select="()"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="in-zip" as="xs:boolean" select="normalize-space($href-zip) ne ''"/>
        <xsl:if test="$in-zip">
          <xsl:attribute name="href-source-zip-result" select="$href-zip"/>
        </xsl:if>

        <!-- Source references: -->
        <xsl:choose>

          <!-- Normal reference, make absolute: -->
          <xsl:when test="(normalize-space(@href-source) ne '') and not($in-zip)">
            <xsl:attribute name="href-source-result" select="local:href-normalize(xtlc:href-concat(($base-source-path, @href-source)))"/>
          </xsl:when>

          <!-- Reference in zip, make sure it is formatted right No protocol, no leading /): -->
          <xsl:when test="(normalize-space(@href-source) ne '') and $in-zip">
            <xsl:variable name="href-source-normalized" as="xs:string" select="xtlc:href-protocol-remove(xtlc:href-canonical(@href-source))"/>
            <xsl:attribute name="href-source-result" select="replace($href-source-normalized, '^/+', '')"/>
          </xsl:when>

          <!-- No source info, leave it... -->
          <xsl:otherwise/>

        </xsl:choose>
      </xsl:if>

      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- SUPPORT: -->

  <xsl:function name="local:href-normalize" as="xs:string">
    <xsl:param name="dref" as="xs:string"/>

    <xsl:sequence select="xtlc:href-protocol-add(xtlc:href-canonical($dref), $xtlc:protocol-file, true())"/>
  </xsl:function>

</xsl:stylesheet>
