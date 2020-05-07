<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:array="http://www.w3.org/2005/xpath-functions/array" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xtlc="http://www.xtpxlib.nl/ns/common"
  xmlns:xtlcon="http://www.xtpxlib.nl/ns/container" xmlns:local="#local.t2g_zy5_xkb" version="3.0" exclude-inline-prefixes="#all"
  type="xtlcon:load-from-container">

  <p:documentation>
    Step that loads the files from a container and TBD
  </p:documentation>

  <!-- ================================================================== -->
  <!-- SETUP: -->

  <p:input port="source" primary="true" sequence="false" content-types="xml">
    <p:documentation>The container to load</p:documentation>
  </p:input>

  <p:option name="href-target-path" as="xs:string?" required="false" select="()">
    <p:documentation>Base path where to write the documents, used for computing the target locations. 
      When you specify this it will have precedence over a /*/@href-target-path.
    </p:documentation>
  </p:option>
  
  <p:option name="main-pipeline-static-base-uri" as="xs:string" required="true">
    <p:documentation></p:documentation>
  </p:option>
  
  <p:output port="result" primary="true" sequence="true" content-types="any">
    <p:documentation>The resulting documents</p:documentation>
  </p:output>

  <p:output port="container" primary="false" sequence="false" content-types="xml" pipe="@amend-container">
    <p:documentation>The original container, amended with additional shadow attributes for the paths and filenames.</p:documentation>
  </p:output>

  <!-- ================================================================== -->

  <p:xslt name="amend-container"
    parameters="map{ 
      'href-target-path': $href-target-path, 
      'base-uri': p:document-property(., 'base-uri'), 
      'pipeline-static-base-uri': $main-pipeline-static-base-uri 
    }">
    <p:with-option name="global-context-item" select="."/>
    <p:with-input port="stylesheet" href="xsl-load-from-container/compute-container-paths.xsl"/>
  </p:xslt>

  <!-- Get the documents: -->
  <p:for-each>
    <p:with-input select="(xtlcon:document-container/(xtlcon:document | xtlcon:external-document[exists(@_href-source)]))[exists(@_href-target)]"/>

    <p:choose>

      <!-- Embedded documents: -->
      <p:when test="exists(/xtlcon:document)">
        <p:variable name="href-target" as="xs:string" select="string(/*/@_href-target)"/>
        <p:variable name="content-type" as="xs:string" select="string((/*/@content-type, 'text/xml')[1])"/>
        <p:variable name="serialization-attribute-value" as="xs:string" select="translate(string(/*/@serialization), '''', '&quot;')"/>
        <p:variable name="serialization" as="map(xs:string, item()*)?"
          select="if (normalize-space($serialization-attribute-value) eq '') then () else parse-json($serialization-attribute-value)"/>

        <!-- Find out how to save: -->
        <!-- TBD JSONXML! -->
        <p:variable name="is-html" as="xs:boolean" select="$content-type  eq 'text/html'"/>
        <p:variable name="is-xhtml" as="xs:boolean" select="$content-type eq 'application/xhtml+xml'"/>
        <p:variable name="is-xml" as="xs:boolean"
          select="not($is-html) and not($is-xhtml) and (($content-type = ('application/xml', 'text/xml')) or ends-with($content-type, '+xml'))"/>
        <p:variable name="is-text" select="not($is-xml) and not($is-html) and starts-with($content-type, 'text/')"/>
        <p:variable name="is-json" as="xs:boolean" select="$content-type eq 'application/json'"/>
        <p:variable name="is-jsonxml" as="xs:boolean" select="$content-type eq 'application/json+xml'"/>
        <p:variable name="method" as="xs:string"
          select="
            if ($is-html) then 'html'
            else if ($is-xhtml) then 'xhtml'
            else if ($is-text) then 'text'
            else if ($is-json or $is-jsonxml) then 'json'
            else 'xml'
          "/>
        <p:variable name="effective-content-type" as="xs:string" select="if ($is-jsonxml) then 'application/json' else $content-type"/>
        <p:variable name="base-serialization-map" as="map(xs:string, item()*)"
          select="map{ 
            'method': $method, 
            'media-type': $effective-content-type,
            'omit-xml-declaration': if ($is-xml) then false() else true()
          }"/>

        <!-- Get the document ready: -->
        <p:unwrap match="/*"/>
        <p:try>
          <p:cast-content-type content-type="{$effective-content-type}"/>
          <p:catch>
            <p:variable name="error" as="element(c:error)" select="/c:errors/c:error[1]" pipe="error"/>
            <p:variable name="message" as="xs:string" select="'[' || $error/@code || '] ' || string($error)" />
            <p:error code="xtlcon:err-content-type">
              <p:with-input>
                <p:inline>Error converting xtpxlib container contents (target: "{$href-target}") to {$effective-content-type}: {$message}</p:inline>
              </p:with-input>
            </p:error>            
          </p:catch>
        </p:try>
        <p:set-properties>
          <p:with-option name="properties"
            select="map{
              'href-target': $href-target,
              'serialization': map:merge(($serialization, $base-serialization-map))            
            }"/>
        </p:set-properties>
      </p:when>

      <!-- External document: -->
      <p:otherwise>
        <p:variable name="href-source" as="xs:string" select="string(/*/@_href-source)"/>
        <p:variable name="href-target" as="xs:string" select="string(/*/@_href-target)"/>
        <p:variable name="href-source-zip" as="xs:string?" select="xs:string(/*/@_href-source-zip)"/>

        <p:choose>
          <!-- File from disk: -->
          <p:when test="empty($href-source-zip)">
            <p:load href="{$href-source}" content-type="application/octet-stream"/>
          </p:when>
          <!-- File from zip: -->
          <p:otherwise>
            <p:variable name="href-source-regexp-escaped-anchored" select="'^' || replace($href-source, '([.\\?*+|\^${}()])', '\\$1') || '$'"/>
            <p:unarchive format="zip">
              <p:with-input port="source" href="{$href-source-zip}"/>
              <p:with-option name="include-filter" select="$href-source-regexp-escaped-anchored"/>
              <p:with-option name="override-content-types" select="[ [$href-source-regexp-escaped-anchored, 'application/octet-stream'] ]"/>
            </p:unarchive>
          </p:otherwise>
        </p:choose>

        <p:set-properties>
          <p:with-option name="properties" select="map{
              'href-target': $href-target
            }"/>
        </p:set-properties>
      </p:otherwise>

    </p:choose>

  </p:for-each>






</p:declare-step>
