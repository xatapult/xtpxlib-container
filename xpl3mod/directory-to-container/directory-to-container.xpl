<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map" xmlns:array="http://www.w3.org/2005/xpath-functions/array"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xtlc="http://www.xtpxlib.nl/ns/common"
  xmlns:xtlcon="http://www.xtpxlib.nl/ns/container" xmlns:local="#local.t2g_zy5_xkb" version="3.0"
  exclude-inline-prefixes="#all" type="xtlcon:directory-to-container">

  <p:documentation>
    Loads a directory (with optional sub-directories) into an xtpxlib (3) container structure.
  </p:documentation>

  <!-- ================================================================== -->
  <!-- SETUP: -->

  <p:import href="../../../xtpxlib-common/xpl3mod/recursive-directory-list/recursive-directory-list.xpl"/>
  <p:import href="../local/load-for-container.xpl"/>

  <p:option name="develop" as="xs:boolean" static="true" select="false()"/>

  <!-- ======================================================================= -->
  <!-- PORTS: -->

  <p:output port="result" primary="true" sequence="false" serialization="map{'method': 'xml', 'indent': true()}">
    <p:documentation>The resulting container structure.</p:documentation>
  </p:output>

  <!-- ======================================================================= -->
  <!-- OPTIONS: -->

  <p:option use-when="not($develop)" name="href-source-directory" as="xs:string" required="true">
    <p:documentation>URI of the directory to read.</p:documentation>
  </p:option>
  <p:option use-when="$develop" name="href-source-directory" as="xs:string" required="false"
    select="resolve-uri('test/', static-base-uri())"/>

  <p:option name="include-filter" as="xs:string*" required="false" select="()">
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
      
      The idea behind this is that in some cases you want to write almost the same structure back to disk. Recording the relative source
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
    <p:documentation>Override content types specification (see description of `p:directory-list`).</p:documentation>
  </p:option>

  <!-- ================================================================== -->
  <!-- MAIN: -->

  <!-- Get the directory contents: -->
  <xtlc:recursive-directory-list flatten="true" path="{$href-source-directory}" depth="{$depth}" detailed="true"
    add-decoded="true">
    <p:with-option name="exclude-filter" select="$exclude-filter"/>
    <p:with-option name="include-filter" select="$include-filter"/>
    <p:with-option name="override-content-types" select="$override-content-types"/>
  </xtlc:recursive-directory-list>

  <!-- Load all contents as container parts: -->
  <p:variable name="base-dir" select="/*/@xml:base"/>
  <p:for-each>
    <p:with-input select="/*/c:file"/>

    <xtlcon:load-for-container>
      <p:with-option name="href-source-abs" select="/*/@href-abs"/>
      <p:with-option name="href-source-rel" select="/*/@href-rel-decoded"/>
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
  <p:add-attribute attribute-name="href-source-path" attribute-value="{$base-dir}"/>
  <p:if test="string($href-target-path) ne ''">
    <p:add-attribute attribute-name="href-target-path" attribute-value="{$href-target-path}"/>
  </p:if>

</p:declare-step>
