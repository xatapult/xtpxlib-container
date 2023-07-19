<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map" xmlns:array="http://www.w3.org/2005/xpath-functions/array"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="#local.c33_3tp_4lb"
  xmlns:xtlcon="http://www.xtpxlib.nl/ns/container" version="3.0" type="xtlcon:container-to-zip">

  <p:documentation>
    Writes an xtpxlib (3) container structure to a zip file. A name for the output zip can be specified in 
    either option `$href-target-zip` or on the container in `/*/@href-target-zip`.
  </p:documentation>

  <!-- ================================================================== -->
  <!-- SETUP: -->

  <p:import href="../local/load-from-container.xpl"/>
  <p:import href="../local/report-error.xpl"/>

  <p:option name="develop" as="xs:boolean" static="true" select="false()"/>

  <!-- ======================================================================= -->
  <!-- PORTS: -->

  <p:input port="source" primary="true" sequence="false" content-types="xml">
    <p:document use-when="$develop" href="../zip-to-container/tmp/zip-to-container-output.xml"/>
    <p:documentation>The container to process.</p:documentation>
  </p:input>

  <p:output port="result" primary="true" sequence="false" content-types="xml"
    serialization="map{'method': 'xml', 'indent': true()}" pipe="container@load-from-container">
    <p:documentation>The input container structure with additional shadow attributes filled.</p:documentation>
  </p:output>

  <!-- ======================================================================= -->
  <!-- OPTIONS: -->

  <p:option name="href-target-zip" as="xs:string?" required="false" select="()" use-when="not($develop)">
    <p:documentation>Name of the zip file to write. When you specify this it will have precedence 
      over a `/*/@href-target-zip`.</p:documentation>
  </p:option>
  <p:option name="href-target-zip" as="xs:string?" required="false"
    select="resolve-uri('tmp/out.docx', static-base-uri())" use-when="$develop"/>

  <!-- ======================================================================= -->

  <p:declare-step type="local:create-zip-manifest" name="local-create-zip-manifest">

    <p:input port="source" primary="true" sequence="true" content-types="any">
      <p:documentation>The output documents (including the additional properties) of xtlcon:load-from-container</p:documentation>
    </p:input>
    <p:output port="result" primary="true" sequence="true" content-types="any" pipe="source@local-create-zip-manifest"/>

    <p:output port="manifest" primary="false" sequence="false" content-types="xml" pipe="@archive-manifest">
      <p:documentation>The generated manifest</p:documentation>
    </p:output>

    <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

    <p:for-each>
      <p:variable name="href-target" as="xs:string" select="p:document-property(., 'href-target')"/>
      <p:variable name="base-uri" as="xs:string" select="p:document-property(., 'base-uri')"/>
      <p:identity>
        <p:with-input>
          <c:entry name="{$href-target}" href="{$base-uri}"/>
        </p:with-input>
      </p:identity>
    </p:for-each>
    <p:wrap-sequence wrapper="c:archive" name="archive-manifest"/>

  </p:declare-step>

  <!-- ======================================================================= -->
  <!-- MAIN: -->

  <!-- Load  the contents of the container: -->
  <xtlcon:load-from-container do-container-paths-for-zip="true" main-pipeline-static-base-uri="{static-base-uri()}"
    href-target-zip="{$href-target-zip}" name="load-from-container"/>

  <!-- Create a manifest: -->
  <local:create-zip-manifest name="create-zip-manifest"/>

  <!-- Create the zip and store it in the location as defined on the supplemented manifest: -->
  <p:archive format="zip" name="archive">
    <p:with-input port="manifest" pipe="manifest@create-zip-manifest"/>
  </p:archive>
  <p:store>
    <p:with-option name="href" select="string(/*/@_href-target-zip)" pipe="container@load-from-container"/>
  </p:store>

</p:declare-step>
