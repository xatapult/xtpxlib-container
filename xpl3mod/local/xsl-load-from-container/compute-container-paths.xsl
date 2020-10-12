<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:array="http://www.w3.org/2005/xpath-functions/array" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xtlc="http://www.xtpxlib.nl/ns/common"
  xmlns:xtlcon="http://www.xtpxlib.nl/ns/container" xmlns:local="#local.znd_n5p_4lb" exclude-result-prefixes="#all" expand-text="true">
  <!-- ================================================================== -->
  <!-- 
       Computes all the appropriate paths for a container when using it for a container-to-* operation and
       fills the appropriate shadow attributes.
  -->
  <!-- ================================================================== -->
  <!-- SETUP: -->

  <xsl:output method="xml" indent="no" encoding="UTF-8"/>

  <xsl:mode on-no-match="shallow-copy"/>

  <xsl:include href="../../../../xtpxlib-common/xslmod/general.mod.xsl"/>
  <xsl:include href="../../../../xtpxlib-common/xslmod/href.mod.xsl"/>

  <!-- ================================================================== -->
  <!-- PARAMETERS: -->

  <xsl:param name="do-container-paths-for-zip" as="xs:boolean" required="yes"/>

  <!-- Target zip file as set by the pipeline. If this is set it overrides $root/@href-target-zip. -->
  <xsl:param name="href-target-zip" as="xs:string?" required="true"/>

  <!-- Target path as set by the pipeline. If this is set it overrides $root/@href-target-path. -->
  <xsl:param name="href-target-path" as="xs:string?" required="true"/>

  <!-- The base-uri of the container. Might be empty (when the container was constructed). -->
  <xsl:param name="base-uri" as="xs:string?" required="true"/>

  <!-- The base-uri of the pipeline. USed when every other method of establishing a base path fails. -->
  <xsl:param name="pipeline-static-base-uri" as="xs:string" required="true"/>

  <!-- ================================================================== -->
  <!-- GLOBAL DECLARATIONS: -->

  <xsl:variable name="root" as="element(xtlcon:document-container)" select="/*"/>

  <!-- The base path against which all other relative paths are made absolute. 
    This is either the base-uri of the container document or, if absent, the static base-uri of the pipeline. 
  -->
  <xsl:variable name="global-base-path" as="xs:string">
    <xsl:variable name="base-uri-normalized" as="xs:string?" select="if (normalize-space($base-uri) eq '') then () else xtlc:href-path($base-uri)"/>
    <xsl:variable name="pipeline-path" as="xs:string" select="xtlc:href-path($pipeline-static-base-uri)"/>
    <xsl:sequence select="($base-uri-normalized, $pipeline-path)[1] => local:canonicalize-path()"/>
  </xsl:variable>

  <!-- The path where things are written to. This is either the path set at the pipeline's invocation or the one defined on the root element. 
    Will only be filled if we 're not creating a zip:
  -->
  <xsl:variable name="global-target-path" as="xs:string?">
    <xsl:if test="not($do-container-paths-for-zip)">
      <xsl:variable name="href-target-path-normalized" as="xs:string?"
        select="if (normalize-space($href-target-path) eq '') then () else $href-target-path"/>
      <xsl:variable name="target-path" as="xs:string?"
        select="local:global-canonical-path(($href-target-path-normalized, $root/@href-target-path)[1])"/>
      <xsl:if test="empty($target-path)">
        <xsl:call-template name="xtlc:raise-error">
          <xsl:with-param name="msg-parts" select="'No target path specified for xtpxlib container-to-disk operation'"/>
        </xsl:call-template>
      </xsl:if>
      <xsl:sequence select="$target-path"/>
    </xsl:if>
  </xsl:variable>

  <!-- The full name of the target zip file. Will only be filled if we're creating a zip: -->
  <xsl:variable name="global-target-zip" as="xs:string?">
    <xsl:if test="$do-container-paths-for-zip">
      <xsl:variable name="href-target-zip-normalized" as="xs:string?"
        select="if (normalize-space($href-target-zip) eq '') then () else $href-target-zip"/>
      <xsl:variable name="target-path" as="xs:string?" select="local:global-canonical-path(($href-target-zip-normalized, $root/@href-target-zip)[1])"/>
      <xsl:if test="empty($target-path)">
        <xsl:call-template name="xtlc:raise-error">
          <xsl:with-param name="msg-parts" select="'No target zip specified for xtpxlib container-to-zip operation'"/>
        </xsl:call-template>
      </xsl:if>
      <xsl:sequence select="$target-path"/>
    </xsl:if>
  </xsl:variable>

  <xsl:variable name="global-source-zip" as="xs:string?" select="local:global-canonical-path($root/@href-source-zip)"/>
  <xsl:variable name="global-source-path" as="xs:string?" select="local:global-canonical-path($root/@href-source-path)"/>

  <!-- ================================================================== -->
  <!-- ROOT ELEMENT CHANGES:: -->

  <xsl:template match="/xtlcon:document-container">
    <xsl:copy>
      <xsl:apply-templates select="@* except @*[starts-with(local-name(.), '_')]"/>
      <xsl:choose>
        <xsl:when test="$do-container-paths-for-zip">
          <xsl:attribute name="_href-target-zip" select="$global-target-zip"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="_href-target-path" select="$global-target-path"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="/xtlcon:document-container/@href-source-zip">
    <xsl:call-template name="create-canonical-shadow-attribute">
      <xsl:with-param name="value" select="$global-source-zip"/>
    </xsl:call-template>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:template match="/xtlcon:document-container/@href-source-path">
    <xsl:call-template name="create-canonical-shadow-attribute">
      <xsl:with-param name="value" select="$global-source-path"/>
    </xsl:call-template>
  </xsl:template>

  <!-- ======================================================================= -->
  <!-- (EXTERNAL) DOCUMENT CHANGES: -->

  <xsl:template match="/xtlcon:document-container/(xtlcon:document | xtlcon:external-document)">
    <xsl:variable name="is-external-document" as="xs:boolean" select="exists(self::xtlcon:external-document)"/>
    <xsl:copy>
      <xsl:apply-templates select="@* except @*[starts-with(local-name(.), '_')]"/>
      <xsl:if test="not($is-external-document)">
        <xsl:attribute name="_document-index" select="count(preceding-sibling::xtlcon:document) + 1"/>
      </xsl:if>

      <!-- Since we're only going to write stuff when this thing has a @href-target, we don't have to do anything when it doesn't have this: -->
      <xsl:if test="normalize-space(@href-target) ne ''">

        <!-- If we are on an external document we might have to read the source from either zip file or disk.
          Compute the canonical shadow attributes: -->
        <xsl:variable name="from-zip" as="xs:boolean"
          select="if (xtlc:str2bln(@not-in-zip, false())) then false() else (exists(@href-source-zip) or exists($global-source-zip))"/>
        <xsl:if test="$is-external-document">
          <xsl:call-template name="create-canonical-shadow-attribute">
            <xsl:with-param name="path-attribute" select="@href-source-zip"/>
            <xsl:with-param name="path-attribute-name" select="'href-source-zip'"/>
            <xsl:with-param name="value" select="local:global-canonical-path(@href-source-zip)"/>
            <xsl:with-param name="default" select="$global-source-zip"/>
            <xsl:with-param name="enabled" select="$from-zip"/>
          </xsl:call-template>
          <xsl:call-template name="create-canonical-shadow-attribute">
            <xsl:with-param name="path-attribute" select="@href-source"/>
            <xsl:with-param name="value" select="if ($from-zip) then @href-source else local:get-canonical-path($global-source-path, @href-source)"/>
          </xsl:call-template>
        </xsl:if>

        <!-- Compute the target: -->
        <xsl:choose>
          <xsl:when test="$do-container-paths-for-zip">
            <xsl:variable name="href-target" as="xs:string" select="string(@href-target) => translate('\', '/')"/>
            <xsl:choose>
              <xsl:when test="not(xtlc:href-is-absolute($href-target))">
                <xsl:call-template name="create-canonical-shadow-attribute">
                  <xsl:with-param name="path-attribute" select="@href-target"/>
                  <xsl:with-param name="value" select="$href-target"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="xtlc:raise-error">
                  <xsl:with-param name="msg-parts" select="('Zip file target ', xtlc:q(@href-target), ' is not a relative path')"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="create-canonical-shadow-attribute">
              <xsl:with-param name="path-attribute" select="@href-target"/>
              <xsl:with-param name="value" select="xtlc:href-add-encoding(local:get-canonical-path($global-target-path, @href-target))"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>

      </xsl:if>

      <!-- Copy contents also: -->
      <xsl:apply-templates/>
      
    </xsl:copy>

  </xsl:template>

  <!-- ======================================================================= -->
  <!-- SUPPORT CODE: -->

  <xsl:template name="create-canonical-shadow-attribute" as="attribute()*">
    <xsl:param name="path-attribute" as="attribute()?" required="false" select="."/>
    <xsl:param name="path-attribute-name" as="xs:string" required="false"
      select="if (exists($path-attribute)) then local-name($path-attribute) else ''"/>
    <xsl:param name="value" as="xs:string?" required="true"/>
    <xsl:param name="default" as="xs:string?" required="false" select="()"/>
    <xsl:param name="enabled" as="xs:boolean" required="false" select="true()"/>

    <!-- Always output the original: -->
    <xsl:copy-of select="$path-attribute"/>
    <!-- If we have a value for this, output the canonical equivalent attribute: -->
    <xsl:if test="$enabled and ($path-attribute-name ne '')">
      <xsl:variable name="canonical-attribute-value" as="xs:string" select="($value, $default)[1]"/>
      <xsl:if test="exists($canonical-attribute-value)">
        <xsl:attribute name="_{$path-attribute-name}" select="$canonical-attribute-value"/>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:function name="local:get-canonical-path" as="xs:string?">
    <xsl:param name="base-path" as="xs:string"/>
    <xsl:param name="path" as="xs:string?"/>

    <xsl:choose>
      <xsl:when test="normalize-space($path) ne ''">
        <xsl:sequence select="xtlc:href-concat(($base-path, $path)) => local:canonicalize-path()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:function name="local:global-canonical-path" as="xs:string?">
    <xsl:param name="path" as="xs:string?"/>
    <xsl:sequence select="local:get-canonical-path($global-base-path, $path)"/>
  </xsl:function>

  <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

  <xsl:function name="local:canonicalize-path" as="xs:string">
    <xsl:param name="path" as="xs:string"/>
    <xsl:sequence select="xtlc:href-canonical(xtlc:href-protocol-add($path, $xtlc:protocol-file, false()))"/>
  </xsl:function>

</xsl:stylesheet>
