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

 
  <p:archive-manifest>
    <p:with-input href="{$href-source-zip}"/>
  </p:archive-manifest>


</p:declare-step>
