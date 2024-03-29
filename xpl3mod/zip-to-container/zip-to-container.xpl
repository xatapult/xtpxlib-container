<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map" xmlns:array="http://www.w3.org/2005/xpath-functions/array"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xtlc="http://www.xtpxlib.nl/ns/common"
  xmlns:xtlcon="http://www.xtpxlib.nl/ns/container" xmlns:local="#local.t2g_zy5_xkb" version="3.0"
  exclude-inline-prefixes="#all" type="xtlcon:zip-to-container">

  <p:documentation>
   Loads the contents of a zip file (directory depth can be set) into an xtpxlib (3) container structure.
  </p:documentation>

  <!-- ================================================================== -->
  <!-- SETUP: -->

  <p:import href="../local/load-for-container.xpl"/>

  <p:option name="develop" as="xs:boolean" static="true" select="false()"/>

  <!-- ======================================================================= -->
  <!-- PORTS: -->

  <p:output port="result" primary="true" sequence="false" serialization="map{'method': 'xml', 'indent': true()}">
    <p:documentation>The resulting container structure</p:documentation>
  </p:output>

  <!-- ======================================================================= -->
  <!-- OPTIONS: -->
  
  <p:option use-when="not($develop)" name="href-source-zip" as="xs:string" required="true">
    <p:documentation>URI of the zip file to read.</p:documentation>
  </p:option>
  <p:option use-when="$develop" name="href-source-zip" as="xs:string" required="false"
    select="resolve-uri('test/test.docx', static-base-uri())"/>

  <p:option name="include-filter" as="xs:string*" required="false">
    <p:documentation>Optional regular expression include filters.</p:documentation>
  </p:option>

  <p:option name="exclude-filter" as="xs:string*" required="false" select="'\.git/'">
    <p:documentation>Optional regular expression exclude filters. By default, `.git` directories are excluded.</p:documentation>
  </p:option>

  <p:option name="depth" as="xs:integer" required="false" select="-1">
    <p:documentation>The sub-directory depth to go. When lt `0`, all sub-directories are processed.</p:documentation>
  </p:option>

  <p:option use-when="not($develop)" name="load-html" as="xs:boolean" required="false" select="false()">
    <p:documentation>Whether to load HTML files.</p:documentation>
  </p:option>
  <p:option use-when="$develop" name="load-html" as="xs:boolean" required="false" select="true()"/>

  <p:option use-when="not($develop)" name="load-text" as="xs:boolean" required="false" select="false()">
    <p:documentation>Whether to load text files.</p:documentation>
  </p:option>
  <p:option use-when="$develop" name="load-text" as="xs:boolean" required="false" select="true()"/>

  <p:option use-when="not($develop)" name="load-json" as="xs:boolean" required="false" select="false()">
    <p:documentation>Whether to load JSON files.</p:documentation>
  </p:option>
  <p:option use-when="$develop" name="load-json" as="xs:boolean" required="false" select="true()"/>

  <p:option use-when="not($develop)" name="json-as-xml" as="xs:boolean" required="false" select="false()">
    <p:documentation>When JSON files are loaded (`option $load-json` is `true`): whether to add them to the container as XML or as JSON text.
      It will set the entry's content type to `application/json+xml`.
    </p:documentation>
  </p:option>
  <p:option use-when="$develop" name="json-as-xml" as="xs:boolean" required="false" select="true()"/>

  <p:option name="add-document-target-paths" as="xs:boolean" required="false" select="false()">
    <p:documentation>Copies the relative source path as the target path `@target-path` for the individual documents.
      
      The idea behind this is that in some cases you want to write almost the same structure back to disk or zip. Recording the relative source
      path as the target path makes this easier: you don't have to set it explicitly.
    </p:documentation>
  </p:option>

  <p:option name="href-target-path" as="xs:string?" required="false" select="()">
    <p:documentation>Optional target path to record on the container.
      
      The idea behind this is that this makes it easier to write the container back to another location on disk, the target path is
      already there.
    </p:documentation>
  </p:option>

  <p:option name="override-content-types" as="array(array(xs:string))?" required="false" select="()">
    <p:documentation>Override content types specification (see description of `p:archive-manifest`).</p:documentation>
  </p:option>

  <!-- ================================================================== -->
  <!-- MAIN: -->

  <!-- Get the archive's contents and decode the names (remove the % encodings) -->
  <p:archive-manifest>
    <p:with-input href="{$href-source-zip}"/>
    <p:with-option name="override-content-types" select="$override-content-types"/>
  </p:archive-manifest>
  
  <p:xslt>
    <p:with-input port="stylesheet" href="xsl/decode-names.xsl"/>
  </p:xslt>

  <!-- Filter it according to the include and exclude filter settings: -->
  <p:if test="exists($include-filter) or exists($exclude-filter)">
    <p:viewport match="c:entry">
      <p:variable name="name" as="xs:string" select="/*/@name"/>
      <p:choose>
        <!-- Any file that matches an include filter is *in*: -->
        <p:when test="some $regexp in $include-filter satisfies matches($name, $regexp)">
          <p:identity/>
        </p:when>
        <p:when test="some $regexp in $exclude-filter satisfies matches($name, $regexp)">
          <p:identity>
            <p:with-input port="source">
              <p:inline>
                <!-- Entry removed because of include/exclude filter settings -->
              </p:inline>
            </p:with-input>
          </p:identity>
        </p:when>
        <p:otherwise>
          <p:identity/>
        </p:otherwise>
      </p:choose>
    </p:viewport>
  </p:if>

  <!-- Filter it according depth: -->
  <p:if test="$depth ge 0">
    <p:viewport match="c:entry">
      <p:variable name="name" as="xs:string" select="/*/@name"/>
      <p:variable name="entry-depth" as="xs:integer" select="count(tokenize($name, '/')[.]) - 1"/>
      <p:choose>
        <p:when test="$entry-depth le $depth">
          <p:identity/>
        </p:when>
        <p:otherwise>
          <p:identity>
            <p:with-input port="source">
              <p:inline>
                <!-- Entry removed because of depth setting -->
              </p:inline>
            </p:with-input>
          </p:identity>
        </p:otherwise>
      </p:choose>
    </p:viewport>
  </p:if>

  <!-- Load the stuff: -->
  <p:for-each>
    <p:with-input select="/*/c:entry"/>
    <xtlcon:load-for-container>
      <p:with-option name="href-zip" select="$href-source-zip"/>
      <p:with-option name="href-source-rel" select="/*/@name"/>
      <p:with-option name="content-type" select="/*/@content-type"/>
      <p:with-option name="load-html" select="$load-html"/>
      <p:with-option name="load-text" select="$load-text"/>
      <p:with-option name="load-json" select="$load-json"/>
      <p:with-option name="json-as-xml" select="$json-as-xml"/>
      <p:with-option name="add-document-target-paths" select="$add-document-target-paths"/>
    </xtlcon:load-for-container>
  </p:for-each>

  <!-- Create the container root element and dress it up with the necessary attributes: -->
  <p:wrap-sequence wrapper="xtlcon:document-container"/>
  <p:add-attribute attribute-name="timestamp" attribute-value="{current-dateTime()}"/>
  <p:add-attribute attribute-name="href-source-zip" attribute-value="{$href-source-zip}"/>
  <p:if test="string($href-target-path) ne ''">
    <p:add-attribute attribute-name="href-target-path" attribute-value="{$href-target-path}"/>
  </p:if>

</p:declare-step>
