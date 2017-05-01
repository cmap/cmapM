# L1000 Data Pipeline v1.2

Copyright (c) 2017, Connectivity Map (CMap) at the Broad Institute All rights reserved.

A description of Matlab routines for processing L1000 data.

### Download Sample data
Processing an entire 384 well plate can take a long time depending on the machine you're running it on. For testing purposes we provide a sample data with a small number of samples. To download the data run the following command:
```matlab
% Download sample dataset
cmapm.Pipeline.download_test_data;
```
This will download and unpack the sample data to the `test_data` folder. A directory of example Level 1 data in the form of .lxb files from a LINCS Joint Project (LJP) plate under the `test_data/level1_data` directory. We also provide pre-computed results in `test_data/pipeline_results` to enable viewing the outputs without running the pipeline and/or to compare their results with CMap's. These outputs are described in the section below.

### Running the standard CMap data processing pipeline
All routines are contained within the `cmapm.Pipeline` Matlab package. By default all outputs are saved in the current working directory, but this can be overridden using the `plate_path` argument to any of the scripts below.

```matlab
% Assumes that MATLAB environment has been set and
% test data has been downloaded as described in the preceding sections.

% Plate to process
plate_name = 'TEST_A375_24H_X1_B20'; % A small test plate
% Parent folder containing Level 1 lxb files for a given plate
raw_path = fullfile(cmapmpath, 'test_data', 'level1_data');
% Path to map files with sample annotations
map_path = fullfile(cmapmpath, 'test_data', 'plate_maps');
% Results folder
plate_path = pwd;

% Run the full pipeline on a plate of data
[gex_ds, qnorm_ds, inf_ds, zs_ds_qnorm, zs_ds_inf] = cmapm.Pipeline.process_plate('plate', plate_name, 'raw_path', raw_path, 'map_path', map_path);

% Run specific components of the pipeline
% Convert a directory of LXB files (level 1) into gene expression (GEX, level 2) matrix.
% here, using example data
gex_ds = cmapm.Pipeline.level1_to_level2('plate', plate_name, 'raw_path', raw_path, 'map_path', map_path)

% Convert the GEX matrix (level 2) to quantile normalized (QNORM, level 3) matrices
% in both landmark and inferred (INF) gene spaces.
[qnorm_ds, inf_ds] = cmapm.Pipeline.level2_to_level3('plate', plate_name, 'plate_path', plate_path)

% Convert the QNORM matrix (level 3) into z-scores (level 4).
% same procedure can be performed using INF matrix (not shown).
zs_ds = cmapm.Pipeline.level3_to_level4(qnorm_ds, 'plate', plate_name, 'plate_path', plate_path)

% Apply moderated z-scoring to level4_to_level5
zsrep_file = fullfile(cmapmpath, 'test_data', 'level4_data', 'TEST_A375_24H_ZSPCINF_n67x22268.gctx' )
col_meta_file = fullfile(cmapmpath, 'test_data', 'level4_data', 'TEST_A375_24H_ZSPCINF.map');
landmark_file = fullfile(cmapmpath, 'resources', 'L1000_EPSILON.R2.chip');
modz_ds = cmapm.Pipeline.level4_to_level5(zsrep_file, col_meta_file, landmark_file, 'rna_well')

```
**Note:** Because the peak detection algorithm is non-deterministic, it's possible that data in levels 2 through 4 could differ slightly for two instances of processing the same plate. The code allows reproducing a previous run by passing a random seed file to the `process_plate` script. We provide such a file at `test_data/rndseed.mat`. Reproducing the results provided in `test_data/pipeline_results` can be done as follows:

```matlab
% Reproduce provided results
[gex_ds, qnorm_ds, inf_ds, zs_ds_qnorm, zs_ds_inf] = cmapm.Pipeline.process_plate('plate', plate_name, 'raw_path', raw_path, 'map_path', map_path, 'rndseed', fullfile(cmapmpath, 'test_data', 'rndseed.mat');
```

#### Description of Pipeline Outputs

| File | Data Level | Gene Space | Description |
| ---- | ----------- | ----------- | ---------- |
| TEST_A375_24H_X1_B20.map | n/a | n/a | Sample annotations file |
| TEST_A375_24H_X1_B20_COUNT_n26x978.gct | n/a | landmark | Matrix of analyte counts per sample|
| TEST_A375_24H_X1_B20_GEX_n26x978.gct | 2 | landmark | gene expression (GEX) values|
| TEST_A375_24H_X1_B20_NORM_n23x978.gct | n/a | landmark | LISS normalized expession profiles |
| TEST_A375_24H_X1_B20_QNORM_n23x978.gct | 3 | landmark | quantile normalized (QNORM) expession profiles |
| TEST_A375_24H_X1_B20_INF_n23x22268.gct | 3 | full | quantile normalized (QNORM) expession profiles |
| TEST_A375_24H_X1_B20_ZSPCQNORM_n23x978.gct | 4 | landmark | differential expression (z-score) signatures |
| TEST_A375_24H_X1_B20_ZSPCINF_n23x22268.gct | 4 | full | differential expression (z-score) signatures |
| dpeak | n/a | n/a | folder containing peak detection outputs and QC |
| liss | n/a | n/a | folder containing LISS outputs and QC |
| calibplot.png |  n/a | n/a | Plot of invariant gene sets for each sample |
| quantile_plots.png |  n/a | n/a | Plot of the normalized and non-normalized expression quantiles |


---
#### Other Tools and Demos (under matlab/demos_and_examples)
* **l1kt_dpeak.m**: Performs peak deconvolution for all analytes in a single LXB file, and outputs a report of the detected peaks.
* **l1kt_plot_peaks.m**: Plots intensity distributions for one or more analytes in an LXB file.
* **l1kt_parse_lxb.m**:	Reads an LXB file and returns the RID and RP1 values.
* **l1kt_liss.m**: Performs Luminex Invariant Set Smoothing on a raw (GEX) input .gct file
* **l1kt_qnorm.m**:	Performs quantile normalization on an input .gct file
* **l1kt_infer.m**:	Infers expression of target genes from expression of landmark genes in an input .gct file

See the documentation included with each script for a details on usage
and input parameters.

#### Demo
* **dpeak_demo.m**: Demo of peak detection. To run the demo, start Matlab, change to the folder containing dpeak_demo and
type dpeak_demo in the Command Window. This will read a sample LXB
file (A10.lxb), generate a number of intensity distribution plots and create a
text report of the statistics of the detected peaks (A10_pkstats.txt).

* **example_methods.m**: Reads in a .gct and a .gctx file, z-score the data in the .gctx file, and read in an .lxb file. To run the demo, start Matlab, change to the folder containing example_methods and type example_methods at the command line.

---
## Common data analysis tasks

### Reading .gct and .gctx files
* **MATLAB**: Use the `parse_gctx` function.

### Creating .gct and .gctx files
* **MATLAB**: Use the `mkgct` and `mkgctx` functions.

### Z-Scoring a data set
* **MATLAB**: Use the `robust_zscore` function. Also see the `example_methods.m` script.

### Reading / converting .lxb files
* **MATLAB**: To read an .lxb into the MATLAB workspace, use the `l1kt_parse_lxb` function.
