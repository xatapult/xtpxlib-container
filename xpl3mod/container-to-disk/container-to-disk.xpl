<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:array="http://www.w3.org/2005/xpath-functions/array" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="#local.c33_3tp_4lb"
  xmlns:xtlcon="http://www.xtpxlib.nl/ns/container" version="3.0" exclude-inline-prefixes="#all">

  <p:documentation>
    
  </p:documentation>

  <!-- ================================================================== -->
  <!-- SETUP: -->

  <p:input port="source" primary="true" sequence="false">
    <p:document href="test/container-example-1.xml"/>
    <p:documentation>The container to process.</p:documentation>
  </p:input>

  <p:option name="href-target-path" as="xs:string?" required="false" select="()">
    <p:documentation>Base path where to write the container. When you specify this it will have precedence 
      over a /*/@href-target-path.</p:documentation>
  </p:option>

  <p:option name="remove-target" as="xs:boolean" required="false" select="true()">
    <p:documentation>Whether to attempt to remove the target directory before writing.</p:documentation>
  </p:option>

  <p:output port="result" primary="true" sequence="false" serialization="map{'method': 'xml', 'indent': true()}">
    <p:documentation>The input container structure with some additional attributes filled.</p:documentation>
  </p:output>

  <!-- ================================================================== -->

  <p:xslt
    parameters="map{ 
      'href-target-path': $href-target-path, 
      'base-uri': p:document-property(., 'base-uri'), 
      'pipeline-static-base-uri': static-base-uri() 
    }">
    <p:with-option name="global-context-item" select="."/>
    <p:with-input port="stylesheet" href="xsl/compute-container-paths.xsl"/>
  </p:xslt>

  <!-- Output the embedded documents: -->
  <p:viewport match="xtlcon:document-container/xtlcon:document[exists(@_href-target)]" name="document-storage-viewport">

    <!-- Get base data: -->
    <p:variable name="href-target" as="xs:string" select="string(/*/@_href-target)"/>
    <p:variable name="content-type" as="xs:string" select="string((/*/@content-type, 'text/xml')[1])"/>
    <p:variable name="serialization-attribute-value" as="xs:string" select="translate(string(/*/@serialization), '''', '&quot;')"/>
    <p:variable name="serialization" as="map(xs:string, item()*)?"
      select="if (normalize-space($serialization-attribute-value) eq '') then () else parse-json($serialization-attribute-value)"/>

    <!-- Find out how to save: -->
    <p:variable name="is-html" as="xs:boolean" select="$content-type  eq 'text/html'"/>
    <p:variable name="is-xhtml" as="xs:boolean" select="$content-type eq 'application/xhtml+xml'"/>
    <p:variable name="is-xml" as="xs:boolean"
      select="not($is-html) and not($is-xhtml) and (($content-type = ('application/xml', 'text/xml')) or ends-with($content-type, '+xml'))"/>
    <p:variable name="is-text" select="not($is-xml) and not($is-html) and starts-with($content-type, 'text/')"/>
    <p:variable name="is-json" as="xs:boolean" select="$content-type eq 'application/json'"/>
    <p:variable name="method" as="xs:string"
      select="
        if ($is-html) then 'html'
        else if ($is-xhtml) then 'xhtml'
        else if ($is-text) then 'text'
        else if ($is-json) then 'json'
        else 'xml'
      "/>
    <p:variable name="base-serialization-map" as="map(xs:string, item()*)"
      select="map{ 
          'method': $method, 
          'media-type': $content-type,
          'omit-xml-declaration': if ($is-xml) then false() else true()
        }"/>

    <p:unwrap match="/*"/>
    <p:cast-content-type content-type="{$content-type}"/>
    <p:store href="{$href-target}">
      <p:with-option name="serialization" select="map:merge(($serialization, $base-serialization-map))"/>
    </p:store>

    <p:identity>
      <p:with-input pipe="current@document-storage-viewport"/>
    </p:identity>

  </p:viewport>

  <!-- Output the external documents: -->
  <p:viewport match="xtlcon:document-container/xtlcon:external-document[exists(@_href-target)][exists(@_href-source)]"
    name="external-document-storage-viewport">

    <p:variable name="href-source" as="xs:string" select="string(/*/@_href-source)"/>
    <p:variable name="href-target" as="xs:string" select="string(/*/@_href-target)"/>
    <p:variable name="href-source-zip" as="xs:string?" select="xs:string(/*/@_href-source-zip)"/>

    <p:choose>
      <!-- File from disk: -->
      <p:when test="empty($href-source-zip)">
        <p:load href="{$href-source}" content-type="application/octet-stream"/>
        <p:store href="{$href-target}"/>
      </p:when>
      <!-- File from zip: -->
      <p:otherwise>
        <p:variable name="href-source-regexp-escaped-anchored" select="'^' || replace($href-source, '([.\\?*+|\^${}()])', '\\$1') || '$'"/>
        <p:unarchive format="zip">
          <p:with-input port="source" href="{$href-source-zip}"/>
          <p:with-option name="include-filter" select="$href-source-regexp-escaped-anchored"/>
          <p:with-option name="override-content-types" select="[ [$href-source-regexp-escaped-anchored, 'application/octet-stream'] ]"/>
        </p:unarchive>
        <p:store href="{$href-target}" />
      </p:otherwise>

    </p:choose>
    <p:identity>
      <p:with-input pipe="current@external-document-storage-viewport"/>
    </p:identity>

  </p:viewport>




</p:declare-step>
