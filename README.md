# cmapM: Connectivity Map Analysis in MATLAB&reg;

Copyright (c) 2017, Connectivity Map (CMap) at the Broad Institute. All rights reserved.

## Introduction

cmapM is a library of of MATLAB&reg; routines to process, analyze and visualize Connectivity Map (CMap) data. To learn more about the CMap project at the Broad Institute, please visit [clue.io](https://clue.io). 

All code is made available under the free [3-clause BSD license](LICENSE.txt).

## Initial setup

- Clone the cmapM code repository

```bash
git clone https://github.com/cmap/cmapM
```
- Configure the MATLAB environment and download test data for the demo

```matlab
% within a MATLAB sesssion type:
cd cmapM
setup
```

## Documentation

* [Working with CMap data formats](docs/Formats.md)
* [L1000 data-processing pipeline](docs/DataPipeline.md)
* [Running Connectivity Algorithms with SigTools](docs/SigToolDemo.md)

## Software Requirements

1. Matlab R2014b and above
2. Statistics Toolbox
3. Parallel Processing Toolbox [Optional]

## Citation

If you find cmapM useful in your research, please cite: [Subramanian, A. et al. A Next Generation Connectivity Map: L1000 Platform and the First 1,000,000 Profiles. Cell (2017)](https://doi.org/10.1016/j.cell.2017.10.049)

If you use the GCTx annotated data matrix format in your work, please cite [Enache et al.](https://doi.org/10.1093/bioinformatics/bty784)

## Changelog

- v2.0.0, Jan 4, 2021
	- Added code and documentation for several [Sigtools](https://cmap.github.io/cmap-sig-tools)
	- Added utility functions for L1000 data formats, algorithms and visualizations
	- Updated documentation, tutorials and demo datasets
- v1.0.2, Jun 28, 2017
	- Fix for parse_gctx slicing issue #1
- v1.0.1, May 6, 2017
	- Refactored code from the now deprecated cmap/l1ktools
	- Data and assets have been externalized to keep the repo size small
	- Added Level 4 to Level 5 processing to L1000 data pipeline
- v1.0.0, 2017
	- Initial release


## Contributing

Bug reports, fixes and pull requests are welcome.
