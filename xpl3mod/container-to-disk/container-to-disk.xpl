<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:array="http://www.w3.org/2005/xpath-functions/array" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="#local.c33_3tp_4lb"
  xmlns:xtlcon="http://www.xtpxlib.nl/ns/container" version="3.0" exclude-inline-prefixes="#all">

  <p:documentation>
    Writes an xtpxlib container structure to disk. A base path must be provided, either as option $href-target path or as 
  </p:documentation>

  <!-- ================================================================== -->
  <!-- SETUP: -->

  <p:import href="../local/load-from-container.xpl"/>
  <p:import href="../local/report-error.xpl"/>

  <!-- Development setting: -->
  <p:option name="develop" as="xs:boolean" static="true" select="false()"/>

  <p:input port="source" primary="true" sequence="false">
    <p:document use-when="$develop" href="test/container-example-1.xml"/>
    <p:documentation>The container to process.</p:documentation>
  </p:input>

  <p:option name="href-target-path" as="xs:string?" required="false" select="()">
    <p:documentation>Base path where to write the container. When you specify this it will have precedence 
      over a /*/@href-target-path.</p:documentation>
  </p:option>

  <p:option name="remove-target" as="xs:boolean" required="false" select="true()">
    <p:documentation>Whether to attempt to remove the target directory before writing.</p:documentation>
  </p:option>

  <p:output port="result" primary="true" sequence="false" serialization="map{'method': 'xml', 'indent': true()}" pipe="container@load-from-container">
    <p:documentation>The input container structure with additional shadow attributes filled.</p:documentation>
  </p:output>

  <!-- ================================================================== -->

  <p:declare-step type="local:delete-directory" name="local-delete-directory">

    <p:input port="source" primary="true" sequence="true" content-types="any"/>
    <p:input port="container" primary="false" sequence="false" content-types="xml"/>

    <p:option name="remove-target" as="xs:boolean" required="true"/>

    <p:output port="result" primary="true" sequence="true" content-types="any"/>

    <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

    <p:if test="$remove-target">
      <p:variable name="href-target-path" as="xs:string" select="/*/@_href-target-path" pipe="container@local-delete-directory"/>
      <!-- Do some quick checks so we don't accidentally delete the whole disk or an important directory. 
        It must have at least have 3 path components! -->
      <p:variable name="href-target-path-no-protocol" as="xs:string" select="substring-after($href-target-path, 'file:///')"/>
      <p:if test="count(tokenize($href-target-path-no-protocol, '/')[.]) ge 3">
        <p:file-delete href="{$href-target-path}" recursive="true" fail-on-error="false"/>
      </p:if>
    </p:if>

    <p:identity>
      <p:with-input pipe="source@local-delete-directory"/>
    </p:identity>

  </p:declare-step>

  <!-- ======================================================================= -->

  <xtlcon:load-from-container do-container-paths-for-zip="false" main-pipeline-static-base-uri="{static-base-uri()}"
    href-target-path="{$href-target-path}" name="load-from-container"/>

  <local:delete-directory remove-target="{$remove-target}">
    <p:with-input port="container" pipe="container@load-from-container"/>
  </local:delete-directory>

  <p:for-each>
    <p:variable name="href-target" as="xs:string" select="p:document-property(., 'href-target')"/>
    <p:try>
      <p:store href="{$href-target}"/>
      <p:catch>
        <xtlcon:report-error error-code="xtlcon:error-write" href-target="{p:document-property(., 'href-target-original')}"
          message="Could not write to &quot;{$href-target}&quot;">
          <p:with-input port="source" pipe="error"/>
        </xtlcon:report-error>
      </p:catch>
    </p:try>
  </p:for-each>

</p:declare-step>
