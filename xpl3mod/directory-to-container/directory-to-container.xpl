<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:array="http://www.w3.org/2005/xpath-functions/array" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xtlc="http://www.xtpxlib.nl/ns/common"
  xmlns:xtlcon="http://www.xtpxlib.nl/ns/container" xmlns:local="#local.t2g_zy5_xkb" version="3.0" exclude-inline-prefixes="#all"
  type="xtlcon:directory-to-container">

  <p:documentation>
    TBD
    
    Record the idea behind add-document-target-paths and href-target-path
  </p:documentation>

  <!-- ================================================================== -->
  <!-- SETUP: -->

  <p:import href="../../../xtpxlib-common/xpl3mod/recursive-directory-list/recursive-directory-list.xpl"/>

  <p:option name="href-source-directory" as="xs:string" required="false" select="'file:/C:/Data/Erik/work/xatapult/xtpxlib-container/'">
    <p:documentation>URI of the directory to read.</p:documentation>
  </p:option>

  <p:option name="include-filter" as="xs:string*" required="false">
    <p:documentation>Optional regular expression include filters.</p:documentation>
  </p:option>

  <p:option name="exclude-filter" as="xs:string*" required="false" select="'\.git/'">
    <p:documentation>Optional regular expression exclude filters. By default, git directories are excluded.</p:documentation>
  </p:option>

  <p:option name="depth" as="xs:integer" required="false" select="-1">
    <p:documentation>The sub-directory depth to go. When lt `0`, all sub-directories are processed.</p:documentation>
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

  <xtlc:recursive-directory-list flatten="true" path="{$href-source-directory}" include-filter="{$include-filter}" exclude-filter="{$exclude-filter}"
    depth="{$depth}"/>

  <p:variable name="base-dir" select="/*/@xml:base"/>
  <p:for-each>
    <p:with-input select="/*/c:file"/>

    <p:variable name="href-source-abs" as="xs:string" select="/*/@href-abs"/>
    <p:variable name="href-source-rel" as="xs:string" select="/*/@href-rel"/>

    <p:try>
      <!-- TBD p:output remove? -->
      <p:output content-types="any"/>
      <p:load href="{/*/@href-abs}" content-type="text/xml"/>
      <p:wrap match="/*" wrapper="xtlcon:document"/>
      <p:catch>
        <!-- TBD p:output remove? -->
        <p:output content-types="any"/>
        <p:identity>
          <p:with-input port="source">
            <xtlcon:external-document/>
          </p:with-input>
        </p:identity>
      </p:catch>
    </p:try>
    <!-- Add the relative reference to the document: -->
    <p:add-attribute attribute-name="href-source" attribute-value="{$href-source-rel}"/>
  </p:for-each>

  <!-- Create the container root element and dress it up with the necessary attributes: -->
  <p:wrap-sequence wrapper="xtlcon:document-container"/>
  <p:add-attribute attribute-name="href-source-path" attribute-value="{$base-dir}"/>
  <p:add-attribute attribute-name="timestamp" attribute-value="{current-dateTime()}"/>
  <p:if test="string($href-target-path) ne ''">
    <p:add-attribute attribute-name="href-target-path" attribute-value="{$href-target-path}"/>
  </p:if>

  <!-- Check if we need to record a target-path for the individual files: -->
  <p:if test="$add-document-target-paths">
    <p:viewport match="/*/xtlcon:*[exists(@href-source)]">
      <p:add-attribute attribute-name="href-target" attribute-value="{/*/@href-source}"/>
    </p:viewport>
  </p:if>

</p:declare-step>
