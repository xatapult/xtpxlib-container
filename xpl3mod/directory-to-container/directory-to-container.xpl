<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:array="http://www.w3.org/2005/xpath-functions/array" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xtlc="http://www.xtpxlib.nl/ns/common"
  xmlns:xtlcon="http://www.xtpxlib.nl/ns/container" xmlns:local="#local.t2g_zy5_xkb" version="3.0" exclude-inline-prefixes="#all"
  type="xtlcon:directory-to-container">

  <p:documentation>
    TBD
    
    CHECK DEFAULTS ON ALL OPTIONS AND PORTS
    
    Record the idea behind add-document-target-paths and href-target-path
  </p:documentation>

  <!-- ================================================================== -->
  <!-- SETUP: -->

  <p:import href="../../../xtpxlib-common/xpl3mod/recursive-directory-list/recursive-directory-list.xpl"/>
  <p:import href="../local/load-for-container.xpl"/>

  <!-- TBD remove default and make required -->
  <p:option name="href-source-directory" as="xs:string" required="false"
    select="'file:/C:/Data/Erik/work/xatapult/xtpxlib-container/xpl3mod/directory-to-container/test/'">
    <p:documentation>URI of the directory to read.</p:documentation>
  </p:option>

  <p:option name="include-filter" as="xs:string*" required="false">
    <p:documentation>Optional regular expression include filters.</p:documentation>
  </p:option>

  <p:option name="exclude-filter" as="xs:string*" required="false" select="'\.git/'">
    <p:documentation>Optional regular expression exclude filters. By default, `.git` directories are excluded.</p:documentation>
  </p:option>

  <p:option name="depth" as="xs:integer" required="false" select="-1">
    <p:documentation>The sub-directory depth to go. When lt `0`, all sub-directories are processed.</p:documentation>
  </p:option>

  <p:option name="load-html" as="xs:boolean" required="false" select="false()">
    <p:documentation>Whether to load HTML files.</p:documentation>
  </p:option>

  <p:option name="load-text" as="xs:boolean" required="false" select="true()">
    <p:documentation>Whether to load text files.</p:documentation>
  </p:option>

  <p:option name="load-json" as="xs:boolean" required="false" select="false()">
    <p:documentation>Whether to load JSON files.</p:documentation>
  </p:option>

  <p:option name="json-as-xml" as="xs:boolean" required="false" select="false()">
    <p:documentation>When json files are loaded (`option $load-json` is `true`): whether to add them to the container as XML or as JSON text.
      It will set the entry's content type to `application/json+xml`.
    </p:documentation>
  </p:option>

  <p:option name="add-document-target-paths" as="xs:boolean" required="false" select="false()">
    <p:documentation>Copies the relative source path as the target path `@target-path` for the individual documents.</p:documentation>
  </p:option>

  <p:option name="href-target-path" as="xs:string?" required="false" select="()">
    <p:documentation>Optional target path to record on the container.</p:documentation>
  </p:option>

  <p:option name="override-content-types" as="array(array(xs:string))?" required="false" select="()">
    <p:documentation>Override content types specification (see description of `p:directory-list`).</p:documentation>
  </p:option>

  <p:output port="result" primary="true" sequence="false" serialization="map{'method': 'xml', 'indent': true()}">
    <p:documentation>The resulting container structure</p:documentation>
  </p:output>

  <!-- ================================================================== -->

  <xtlc:recursive-directory-list flatten="true" path="{$href-source-directory}" depth="{$depth}" detailed="true">
    <!-- Since include/exclude filters can be sequences of strings, we'll have to pass them by p:with-option (and not as attribute): -->
    <p:with-option name="exclude-filter" select="$exclude-filter"/>
    <p:with-option name="include-filter" select="$include-filter"/>
    <p:with-option name="override-content-types" select="$override-content-types"/>
  </xtlc:recursive-directory-list>

  <p:variable name="base-dir" select="/*/@xml:base"/>
  <p:for-each>
    <p:with-input select="/*/c:file"/>

    <xtlcon:load-for-container>
      <p:with-option name="href-source-abs" select="/*/@href-abs"/>
      <p:with-option name="href-source-rel" select="/*/@href-rel"/>
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
  <p:add-attribute attribute-name="href-source-path" attribute-value="{$base-dir}"/>
  <p:add-attribute attribute-name="timestamp" attribute-value="{current-dateTime()}"/>
  <p:if test="string($href-target-path) ne ''">
    <p:add-attribute attribute-name="href-target-path" attribute-value="{$href-target-path}"/>
  </p:if>


</p:declare-step>
