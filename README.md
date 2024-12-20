<?xml version="1.0" encoding="UTF-8"?>
<README xml:space="preserve"># `xtpxlib-container`: Xatapult XML Library - Support for XML containers (multiple files wrapped into one)

**Xatapult Content Engineering - [`http://www.xatapult.com`](http://www.xatapult.com)**

---------- 

XML Containers provide support for working with multiple related files by wrapping them into a single one. 
Binary files are referenced instead of included. 

The container structure is standardized. Once contents is in a container it's easy to analyze, change and/or write back. 
It can also be used to create a whole file structure, in a container, and then write it out to disk or zip file.

The `xtpxlib-container` component has XProc (1.0 and 3.0) pipelines for:
* Reading the contents of a zip file or directory structure into a container
* Writing a container out to a zip file or disk

## Technical information

Component version: V3.0 - 2024-12-12

Documentation: [`https://container.xtpxlib.org`](https://container.xtpxlib.org)

Git URI: `git@github.com:xatapult/xtpxlib-container.git`

Git site: [`https://github.com/xatapult/xtpxlib-container`](https://github.com/xatapult/xtpxlib-container)
      
This component depends on:
* [`xtpxlib-common`](https://common.xtpxlib.org) (Common component: Shared libraries and IDE support)

## Version history

**V3.0 - 2024-12-12 (current)**

Deprecation of XProc 1.0. Several fixes.

**V2.0 - 2023-07-19**

Added XProc 3.0 support.

**V1.1 - 2020-10-15**

Added first versions of the 3.0 container pipelines.

**V1.0.B - 2020-04-09**

Bugfix for copying binary files referenced from a container.

**V1.0.A - 2020-02-16**

New logo and minor fixes

**V1.0 - 2019-12-18**

Initial release

**V0.9 - 2019-12-11**

Pre-release to test GitHub pages functionality.


-----------
*Generated: 2024-12-12 15:10:10*

</README>