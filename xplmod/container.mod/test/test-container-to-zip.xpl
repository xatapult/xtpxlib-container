<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" version="1.0" xpath-version="2.0"
  exclude-inline-prefixes="#all" xmlns:xtlcon="http://www.xtpxlib.nl/ns/container">

  <p:documentation>
   Test driver for the container-to-zip step.
  </p:documentation>

  <!-- ================================================================== -->
  <!-- SETUP: -->

  <p:input port="source" primary="true" sequence="false">
    <p:document href="test-container.xml"/>
  </p:input>

  <p:option name="tmp-base-dir" required="false" select="resolve-uri('../../../tmp', static-base-uri())"/>

  <p:output port="result" primary="true" sequence="false"/>
  <p:serialization port="result" method="xml" encoding="UTF-8" indent="true" omit-xml-declaration="false"/>

  <p:import href="../container.mod.xpl"/>

  <!-- ================================================================== -->

  <xtlcon:container-to-zip>
    <p:with-option name="href-target-zip" select="concat($tmp-base-dir, '/C2Z.zip')"/>
  </xtlcon:container-to-zip>

</p:declare-step>
