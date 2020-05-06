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

  <p:import href="../local/load-for-container.xpl"/>
  
  <!-- TBD remove default and make required -->
  <p:option name="href-source-zip" as="xs:string" required="false" select="resolve-uri('test/test-contents.zip', static-base-uri())">
    <p:documentation>URI of the directory to read.</p:documentation>
  </p:option>

  <p:option name="include-filter" as="xs:string*" required="false">
    <p:documentation>Optional regular expression include filters.</p:documentation>
  </p:option>

  <p:option name="exclude-filter" as="xs:string*" required="false" select="'\.txt$'">
    <!-- select="'\.git/'" -->
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

  <p:option name="load-json" as="xs:boolean" required="false" select="true()">
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
    <p:documentation>Override content types specification (see description of `p:archive-manifest`).</p:documentation>
  </p:option>

  <p:output port="result" primary="true" sequence="false" serialization="map{'method': 'xml', 'indent': true()}">
    <p:documentation>The resulting container structure</p:documentation>
  </p:output>

  <!-- ================================================================== -->

  <!-- Get the archive's contents: -->
  <p:archive-manifest>
    <p:with-input href="{$href-source-zip}"/>
    <p:with-option name="override-content-types" select="$override-content-types"/>
  </p:archive-manifest>

  <!-- Filter it according to the include and exclude filter settings: -->
  <p:if test="exists($include-filter) or exists($exclude-filter)">
    <p:viewport match="c:entry">
      <p:variable name="name" as="xs:string" select="/*/@name"/>
      <p:choose>
        <!-- Any file that matches an include filter is *in*: -->
        <p:when test="some $regexp in $include-filter satisfies matches($name, $regexp)">
          <p:identity/>
        </p:when>
        <p:when test="some $regexp in $exclude-filter satisfies matches($name, $regexp)">
          <p:identity>
            <p:with-input port="source">
              <p:inline>
                <!-- Entry removed because of include/exclude filter settings -->
              </p:inline>
            </p:with-input>
          </p:identity>
        </p:when>
        <p:otherwise>
          <p:identity/>
        </p:otherwise>
      </p:choose>
    </p:viewport>
  </p:if>
  
  <!-- Filter it according depth: -->
  <p:if test="$depth ge 0"> 
    <p:viewport match="c:entry">
      <p:variable name="name" as="xs:string" select="/*/@name"/>
      <p:variable name="entry-depth" as="xs:integer" select="count(tokenize($name, '/')[.]) - 1"/>
      <p:choose>
        <p:when test="$entry-depth le $depth">
          <p:identity/>
        </p:when>
        <p:otherwise>
          <p:identity>
            <p:with-input port="source">
              <p:inline>
                <!-- Entry removed because of depth setting -->
              </p:inline>
            </p:with-input>
          </p:identity>
        </p:otherwise>
      </p:choose>
    </p:viewport>
  </p:if>

  <!-- Load the stuff: -->
  <p:for-each >
    <p:with-input select="/*/c:entry"/>
    
    <xtlcon:load-for-container>
      <p:with-option name="href-zip" select="$href-source-zip"/>
      <p:with-option name="href-source-rel" select="/*/@name"/>
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
  <p:add-attribute attribute-name="href-source-zip" attribute-value="{$href-source-zip}"/>
  <p:if test="string($href-target-path) ne ''">
    <p:add-attribute attribute-name="href-target-path" attribute-value="{$href-target-path}"/>
  </p:if>

</p:declare-step>
