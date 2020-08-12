<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:array="http://www.w3.org/2005/xpath-functions/array" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xtlc="http://www.xtpxlib.nl/ns/common"
  xmlns:xtlcon="http://www.xtpxlib.nl/ns/container" xmlns:local="#local.t2g_zy5_xkb" version="3.0" exclude-inline-prefixes="#all"
  type="xtlcon:load-from-container">

  <p:documentation>
    Step that loads the files as specified by a container that need to be written to disk:
    - Only loads the documents for which an `href-target` is there
    - For every document loaded, it adds the following additional properties:
      - href-target: The actual target URI for the document (absolute for writing to disk, relative for writing to zips)s
      - href-target-original: The original value as set by @href-target
      = base-uri: This is mangled so it is unique (necessary for creating the zip since we need to address the loaded files as unique 
        by their base-uris). No longer reflects anything in the real world any more!
    - For documents stated *in* the container, it sets the property:
      - serialization: The serialization options for this document (including, most importantly, method and media-type)
    - External documents are always loaded as application/octet-stream.
    
    Provides an additional output port "container" that outputs the original contain er supplemented with all the appropriate
    shadow (starting with _) attributes.
  </p:documentation>

  <!-- ================================================================== -->
  <!-- SETUP: -->

  <p:import href="report-error.xpl"/>

  <p:input port="source" primary="true" sequence="false" content-types="xml">
    <p:documentation>The container to load</p:documentation>
  </p:input>
  
  <p:option name="do-container-paths-for-zip" as="xs:boolean" required="true">
    <p:documentation>Set to true for container-to-zip, false otherwise.</p:documentation>
  </p:option>
  
  <p:option name="href-target-zip" as="xs:string?" required="false" select="()">
    <p:documentation>Zip file location. When you specify this it will have precedence over a /*/@href-target-zip.
    </p:documentation>
  </p:option>
  
  <p:option name="href-target-path" as="xs:string?" required="false" select="()">
    <p:documentation>Base path where to write the documents, used for computing the target locations. 
      When you specify this it will have precedence over a /*/@href-target-path.
    </p:documentation>
  </p:option>

  <p:option name="main-pipeline-static-base-uri" as="xs:string" required="true">
    <p:documentation>The `static-base-uri()` of the calling pipeline.</p:documentation>
  </p:option>

  <p:output port="result" primary="true" sequence="true" content-types="any">
    <p:documentation>The resulting documents with some additional document properties (see pipeline description).</p:documentation>
  </p:output>

  <p:output port="container" primary="false" sequence="false" content-types="xml" pipe="@amend-container">
    <p:documentation>The original container, supplemented with additional shadow attributes for the paths and filenames.</p:documentation>
  </p:output>

  <!-- ================================================================== -->

  <p:xslt name="amend-container"
    parameters="map{ 
      'do-container-paths-for-zip': $do-container-paths-for-zip,
      'href-target-zip': $href-target-zip, 
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
    <p:variable name="index" as="xs:integer" select="p:iteration-position()"/>

    <p:variable name="href-target-original" as="xs:string?" select="xs:string(/*/@href-target)"/>
    <p:variable name="href-target" as="xs:string" select="string(/*/@_href-target)"/>

    <p:choose>

      <!-- Load embedded documents: -->
      <p:when test="exists(/xtlcon:document)">
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
            <xtlcon:report-error error-code="xtlcon:err-content-type" href-target="{$href-target-original}"
              message="Error converting embedded document in container to {$effective-content-type}">
              <p:with-input port="source" pipe="error"/>
            </xtlcon:report-error>
          </p:catch>
        </p:try>
        <!-- Set the document properties for the embedded document: -->
        <p:set-properties>
          <p:with-option name="properties"
            select="map{
              'base-uri': p:document-property(., 'base-uri') || '-' || $index,
              'href-target': $href-target,
              'href-target-original': $href-target-original,
              'serialization': map:merge(($serialization, $base-serialization-map))            
            }"
          />
        </p:set-properties>
      </p:when>

      <!-- Load external document: -->
      <p:otherwise>
        <p:variable name="href-source" as="xs:string" select="string(/*/@_href-source)"/>
        <p:variable name="href-source-zip" as="xs:string?" select="xs:string(/*/@_href-source-zip)"/>

        <p:choose>
          <!-- File from disk: -->
          <p:when test="empty($href-source-zip)">
            <p:try>
              <p:load href="{$href-source}" content-type="application/octet-stream"/>
              <p:catch>
                <xtlcon:report-error error-code="xtlcon:error-load" href-target="{$href-target-original}"
                  message="Could not load &quot;{$href-source}&quot;">
                  <p:with-input port="source" pipe="error"/>
                </xtlcon:report-error>
              </p:catch>
            </p:try>
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
        <!-- Set the document properties for the external document: -->
        <p:set-properties>
          <p:with-option name="properties"
            select="map{
              'base-uri': p:document-property(., 'base-uri') || '-' || $index,
              'href-target': $href-target,
              'href-target-original': $href-target-original
            }"/>
        </p:set-properties>
      </p:otherwise>

    </p:choose>

  </p:for-each>

</p:declare-step>
