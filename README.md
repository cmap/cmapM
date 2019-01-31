cmapM: Connectivity Map Analysis in MATLAB&reg;
===============================================
Copyright (c) 2017, Connectivity Map (CMap) at the Broad Institute. All rights reserved.

Introduction
------------
cmapM is a collection of MATLAB routines for analyzing data from the [Connectivity Map project](https://clue.io) and made available under the free [3-clause BSD license](LICENSE.txt).

Initial setup
---
After cloning the `cmapM` github repo. Change to the cmapM folder and run the
following from the Matlab command window to setup environment variables,
add cmapM to the Matlab search path, and download asset files:
```matlab
setup
```

Contents
--------
* [Working with CMap data formats](docs/Formats.md)
* [L1000 data-processing pipeline](docs/DataPipeline.md)

Software Requirements
---------------------
1. Matlab R2014b and above
2. Statistics Toolbox
3. Parallel Processing Toolbox [Optional]

Contributions
-------------
Bug reports, fixes and pull requests are welcome.

Citation
--------

If you use GCTx and/or cmapM in your work, please cite [Enache et al.](https://www.biorxiv.org/content/early/2017/11/30/227041)
