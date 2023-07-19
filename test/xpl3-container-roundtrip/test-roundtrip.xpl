<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map" xmlns:array="http://www.w3.org/2005/xpath-functions/array"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="#local.e3y_33h_ywb"
  xmlns:xtlcon="http://www.xtpxlib.nl/ns/container" version="3.0" exclude-inline-prefixes="#all" name="this">

  <p:import href="../../xpl3mod/zip-to-container/zip-to-container.xpl"/>
  <p:import href="../../xpl3mod/container-to-zip/container-to-zip.xpl"/>

  <!-- ======================================================================= -->

  <p:variable name="filename-in" as="xs:string" select="'test.docx'"/>
  <p:variable name="filename-out" as="xs:string" select="'result-' || $filename-in"/>

  <p:variable name="href-in" as="xs:string" select="resolve-uri($filename-in, static-base-uri())"/>
  <p:variable name="href-out" as="xs:string" select="resolve-uri($filename-out, static-base-uri())"/>

  <p:variable name="href-container" as="xs:string" select="resolve-uri('container.xml', static-base-uri())"/>

  <xtlcon:zip-to-container p:message="*** Reading from: {$href-in}">
    <p:with-option name="href-source-zip" select="$href-in"/>
    <p:with-option name="add-document-target-paths" select="true()"/>
  </xtlcon:zip-to-container>

  <p:store href="{$href-container}" serialization="map{'method': 'xml', 'indent': true()}"/>

  <xtlcon:container-to-zip p:message="*** Writing to: {$href-out}">
    <p:with-option name="href-target-zip" select="$href-out"></p:with-option>
  </xtlcon:container-to-zip>
  
</p:declare-step>
