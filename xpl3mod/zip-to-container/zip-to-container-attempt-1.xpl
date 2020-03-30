<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:array="http://www.w3.org/2005/xpath-functions/array" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xtlc="http://www.xtpxlib.nl/ns/common"
  xmlns:xtlcon="http://www.xtpxlib.nl/ns/container" xmlns:local="#local.t2g_zy5_xkb" version="3.0" exclude-inline-prefixes="#all"
  type="xtlcon:zip-to-container">

  <p:documentation>
    TBD
    
    Record the idea behind add-document-target-paths and href-target-path
  </p:documentation>

  <!-- ================================================================== -->
  <!-- SETUP: -->

  <!-- TBD remove default and make required -->
  <p:option name="href-source-zip" as="xs:string" required="false" select="resolve-uri('test/test-contents.zip', static-base-uri())">
    <p:documentation>URI of the directory to read.</p:documentation>
  </p:option>

  <p:option name="include-filter" as="xs:string*" required="false">
    <p:documentation>Optional regular expression include filters.</p:documentation>
  </p:option>

  <p:option name="exclude-filter" as="xs:string*" required="false" select="'\.git/'">
    <p:documentation>Optional regular expression exclude filters. By default, git directories are excluded.</p:documentation>
  </p:option>

  <p:option name="add-document-target-paths" as="xs:boolean" required="false" select="false()">
    <p:documentation>Copies the relative source path as the target path `@target-path` for the individual documents.</p:documentation>
  </p:option>

  <p:option name="href-target-path" as="xs:string?" required="false" select="()">
    <p:documentation>Optional target path to record on the container.</p:documentation>
  </p:option>

  <p:output port="result" primary="true" sequence="false" serialization="map{'method': 'xml', 'indent': true()}">
    <p:documentation>TBD</p:documentation>
  </p:output>

  <!-- ================================================================== -->

  <p:variable name="href-source-zip-urified" as="xs:string" select="p:urify($href-source-zip)"/>
  
  <p:unarchive>
    <p:with-input href="{$href-source-zip-urified}"/>
    <!-- Since include/exclude filters can be sequences of strings, we'll have to pass them by p:with-option (and not as attribute): -->
    <p:with-option name="exclude-filter" select="$exclude-filter"/>
    <p:with-option name="include-filter" select="$include-filter"/>
  </p:unarchive>

  <p:for-each name="step-file-examination">
    <p:variable name="href-document" select="p:document-property(., 'base-uri')"/>
    <p:variable name="content-type-document" select="p:document-property(., 'content-type')"/>
    <p:try>
      <!-- TBD: Remove p:output? -->
      <p:output content-types="any"/>
      <p:wrap match="/*" wrapper="xtlcon:document"/>
      <p:catch>
        <!-- TBD: Remove p:output? -->
        <p:output content-types="any"/>
        <!--<p:identity>
          <p:with-input port="source">
            <xtlcon:external-document/>
          </p:with-input>
        </p:identity>-->
        <p:identity>
          <p:with-input pipe="error"/>
        </p:identity>
      </p:catch>
    </p:try>

    <!-- Add the relative reference to the document: -->
    <p:add-attribute attribute-name="href-source" attribute-value="{substring-after($href-document, $href-source-zip-urified || '/')}"/>
    <p:add-attribute attribute-name="content-type" attribute-value="{$content-type-document}"/>

  </p:for-each>

  <!-- Create the container root element and dress it up with the necessary attributes: -->
  <p:wrap-sequence wrapper="xtlcon:document-container"/>
  <p:add-attribute attribute-name="href-source-zip" attribute-value="{$href-source-zip-urified}"/>
  <p:add-attribute attribute-name="timestamp" attribute-value="{current-dateTime()}"/>
  <p:if test="string($href-target-path) ne ''">
    <p:add-attribute attribute-name="href-target-path" attribute-value="{$href-target-path}"/>
  </p:if>


</p:declare-step>
