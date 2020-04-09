<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:array="http://www.w3.org/2005/xpath-functions/array" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xtlc="http://www.xtpxlib.nl/ns/common"
  xmlns:xtlcon="http://www.xtpxlib.nl/ns/container" xmlns:local="#local.t2g_zy5_xkb" version="3.0" exclude-inline-prefixes="#all"
  type="xtlcon:load-for-container">

  <p:documentation>
    Step that loads a single file from a zip or file and performs all the container loading handling.
  </p:documentation>

  <!-- ================================================================== -->
  <!-- SETUP: -->

  <p:option name="href-zip" as="xs:string?" required="false" select="()">
    <p:documentation>Name of the zip file to use. If () load from the file system.</p:documentation>
  </p:option>

  <p:option name="href-source-abs" as="xs:string?" required="false" select="()">
    <p:documentation>Absolute filename of the file to load from the file system. Ignored when loading from zip.</p:documentation>
  </p:option>

  <p:option name="href-source-rel" as="xs:string" required="true">
    <p:documentation>Relative filename of the file to load. Used when loading files from a zip and recorded as @href-source on the entry.</p:documentation>
  </p:option>

  <p:option name="content-type" as="xs:string?" required="true">
    <p:documentation>Expected content-type of the entry.</p:documentation>
  </p:option>

  <p:option name="load-html" as="xs:boolean" required="true">
    <p:documentation>Whether to load HTML files.</p:documentation>
  </p:option>

  <p:option name="load-text" as="xs:boolean" required="true">
    <p:documentation>Whether to load text files.</p:documentation>
  </p:option>

  <p:option name="load-json" as="xs:boolean" required="true">
    <p:documentation>Whether to load JSON files.</p:documentation>
  </p:option>

  <p:option name="json-as-xml" as="xs:boolean" required="true">
    <p:documentation>When json files are loaded (`option $load-json` is `true`): whether to add them to the container as XML or as JSON text.
      It will set the entry's content type to `application/json+xml`.
    </p:documentation>
  </p:option>

  <p:option name="add-document-target-paths" as="xs:boolean" required="true">
    <p:documentation>If true, copies the relative source path as the target path `@target-path` for the individual documents.</p:documentation>
  </p:option>

  <p:output port="result" primary="true" sequence="false">
    <p:documentation>The resulting container entry</p:documentation>
  </p:output>

  <!-- ================================================================== -->

  <!-- Find out what to do: -->
  <p:variable name="is-html" as="xs:boolean" select="$content-type = ('text/html', 'application/xhtml+xml')"/>
  <p:variable name="is-xml" as="xs:boolean"
    select="not($is-html) and (($content-type = ('application/xml', 'text/xml')) or ends-with($content-type, '+xml'))"/>
  <p:variable name="is-text" select="not($is-xml) and not($is-html) and starts-with($content-type, 'text/')"/>
  <p:variable name="is-json" as="xs:boolean" select="$content-type eq 'application/json'"/>
  <p:variable name="do-try-load" as="xs:boolean"
    select="$is-xml or ($load-html and $is-html) or ($load-text and $is-text) or ($load-json and $is-json)"/>

  <p:choose>

    <!--Try to load it and treat is as the content-type we expect. If this fails, handle it as an external reference.: -->
    <p:when test="$do-try-load">
     <!-- <p:try>-->

        <!-- Find out where to load it from and the load it, forced to the right content-type: -->
        <p:choose>
          <p:when test="exists($href-zip)">
            <p:variable name="href-source-rel-regexp-escaped-anchored" select="'^' || replace($href-source-rel, '([.\\?*+|\^${}()])', '\\$1') || '$'"/>
            <p:unarchive format="zip" message="REL: {$href-source-rel-regexp-escaped-anchored} {$content-type}">
              <p:with-input port="source" href="{$href-zip}"/>
              <p:with-option name="include-filter" select="$href-source-rel-regexp-escaped-anchored"/>
              <p:with-option name="override-content-types" select="[ [$href-source-rel-regexp-escaped-anchored, $content-type] ]"/>
            </p:unarchive>
          </p:when>
          <p:otherwise>
            <p:load href="{$href-source-abs}" content-type="{$content-type}"/>
          </p:otherwise>
        </p:choose>

        <!-- See what and how to output: -->
        <p:choose>
          <!-- Text -->
          <p:when test="$is-text">
            <p:identity>
              <p:with-input>
                <xtlcon:document xml:space="preserve">{.}</xtlcon:document>
              </p:with-input>
            </p:identity>
          </p:when>
          <!-- JSON as XML: -->
          <p:when test="$is-json and $json-as-xml">
            <p:cast-content-type content-type="text/xml"/>
            <p:wrap match="/*" wrapper="xtlcon:document"/>
          </p:when>
          <!-- JSON as text: -->
          <p:when test="$is-json">
            <p:identity>
              <p:with-input>
                <xtlcon:document>{serialize(., map{'method': 'json'})}</xtlcon:document>
              </p:with-input>
            </p:identity>
          </p:when>
          <!-- XML: -->
          <p:otherwise>
            <p:wrap match="/*" wrapper="xtlcon:document"/>
          </p:otherwise>
        </p:choose>
        <p:add-attribute attribute-name="content-type"
          attribute-value="{if ($is-json and $json-as-xml) then 'application/json+xml' else $content-type}"/>

        <!-- Could not load or something else went wrong, add as an external binary document: -->
       <!-- <p:catch>
          <p:identity>
            <p:with-input port="source">
              <xtlcon:external-document content-type="application/octet-stream"/>
            </p:with-input>
          </p:identity>
        </p:catch>-->

      <!--</p:try>-->
    </p:when>

    <!-- No load was tried at all, add as an external document: -->
    <p:otherwise>
      <p:identity>
        <p:with-input port="source">
          <xtlcon:external-document content-type="{$content-type}"/>
        </p:with-input>
      </p:identity>
    </p:otherwise>

  </p:choose>

  <!-- Finalize by adding the @href-source and optional @href-target attributes: -->
  <p:add-attribute attribute-name="href-source" attribute-value="{$href-source-rel}"/>
  <p:if test="$add-document-target-paths">
    <p:add-attribute attribute-name="href-target" attribute-value="{$href-source-rel}"/>
  </p:if>

</p:declare-step>
