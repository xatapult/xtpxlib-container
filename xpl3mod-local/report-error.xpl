<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:array="http://www.w3.org/2005/xpath-functions/array" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="#local.iwn_lpp_qlb"
  xmlns:xtlcon="http://www.xtpxlib.nl/ns/container" version="3.0" exclude-inline-prefixes="#all" type="xtlcon:report-error">

  <p:documentation>
    Creates a standard error message for errors occuring in the container pipelines.
  </p:documentation>

  <!-- ================================================================== -->
  <!-- SETUP: -->

  <p:input port="source" primary="true" sequence="true" content-types="any">
    <p:documentation>The original error document (c:errors element).</p:documentation>
  </p:input>

  <p:option name="error-code" as="xs:QName" required="true"/>
  <p:option name="message" as="xs:string" required="true"/>
  <p:option name="href-target" as="xs:string?" required="false" select="()"/>

  <p:output port="result" primary="true" sequence="true" content-types="any">
    <p:documentation>This output port is just here for convenience. No document will ever appear on it 
        because the step always fails.</p:documentation>
    <p:empty/>
  </p:output>

  <!-- ======================================================================= -->

  <p:variable name="original-error" as="element(c:error)" select="/c:errors/c:error[1]"/>
  <p:variable name="original-message" as="xs:string" select="'[' || $original-error/@code || '] ' || string($original-error)"/>
  <p:variable name="target-part" as="xs:string?" select="if (exists($href-target)) then (' (target: &quot;' || $href-target || '&quot;)') else ()"/>

  <p:error>
    <p:with-option name="code" select="$error-code"/>
    <p:with-input>
      <p:inline>{$message}{$target-part}: {$original-message}</p:inline>
    </p:with-input>
  </p:error>

</p:declare-step>
