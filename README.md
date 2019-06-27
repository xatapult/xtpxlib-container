# `xtpxlib-container`: Xatapult XML Library - Container handling

Version, release and dependency information: See `/version.xml` 

Xatapult Content Engineering - http://www.xatapult.nl

Erik Siegel - erik@xatapult.nl - +31 6 53260792

----

**`xtpxlib`** is a library containing software for processing XML, using languages like 
XSLT, XProc etc. It consists of several separate components, named `xtpxlib-*`. Everything can be found on GitHub ([https://github.com/eriksiegel](https://github.com/eriksiegel)).

**`xtpxlib-container`** ([https://github.com/eriksiegel/xtpxlib-container](https://github.com/eriksiegel/xtpxlib-container)) is a component that handles "containers": construction to work with multiple XML and other files in one go. Containers can be read from and written to disk or zip files. Container handling is implemented as an XProc (1.0) step library.

----

## Containers

The trigger for the `xtpxlib` container format came from having to work with Open Office files (like Microsoft Word and Excel). these files are actually zip files with an awful lot of XML inside that all reference each other. It is extremely hard to process this using XLST without having all these files available to your stylesheet. So some kind of wrapper or container format was necessary. 

So an `xtpxlib` container is an XML format that is a wrapper around a set of XML and other files. It is a very useful tool for use cases like:

* Processing a lot of XML files that belong together and reference each other in a single XSLT stylesheet.
* Reading or writing a bunch of files in one operation. For instance to read/write a directory of files or a zip file.

About the format:

* An `xtpxlib` container has the root element `<document-container>`
* The root and all other container elements are in the `http://www.xtpxlib.nl/ns/container` namespace.
* An XML document in the container is wrapped in a `<document>` element.
* Non-XML documents are *referenced* by a `<external-document>` element.
* ALl these elements have attributes that govern their behavior on reads and writes. See the container schema in `/xsd/container.xsd`.

Playing around with the container format can be done by running the pipelines in `/xplmod/container.mod/test/*.xpl`. All these pipelines can be run without specifying an input or options. Results are written to `/tmp`.

----

## Using `xtpxlib`

* Clone the GitHub repository to some appropriate location on disk. That's basicly it for installation.
* If you use more than one `xtpxlib` component, all repositories must be cloned in the same base directory.
* Most libraries depend on `xtpxlib-common`

----

## Library contents

### Directories at root level

| Directory | Description | Remarks |
| --------- | ----------- | --------|
| `etc` | Other files, mostly for use inside oXygen. |  |
| `xplmod` | XProc 1.0 libraries for working with containers. | The steps in the libraries have have header comments describing their functionality. |
| `xsd` | Schema(s) that describe containers. |  |

The subdirectories named `tmp` and  `build` may appear while running parts of the library. These directories are for temporary and build results. Git will ignore them because of the `.gitignore` settings.

Most files contain a header comment about what they're for.

-----
## Implicit conversions

The container `<document>` element has a `@mime-type` attribute. You can use this to trigger some implicit conversions when writing a container to disk or zip:

| `@mime-type` | Result |
| ----------- | ------ |
| `text/plain` | The result will be that the root element of the document will be turned into a string and written as a *text* file. You can use this to, for instance, create a JSON file: just wrap the JSON in some root element and set `mime-type="text/plain"` on the surrounding container `<document>` element.  |
| `application/pdf` | When the document root element is `<fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format">` *and* `mime-type="application/pdf"`, the result will be run through the FOP XSL-FO processor and, on no errors, will result in a PDF. You can optionally pass a FOP initialization file (if you don't, a default will be used). | 

