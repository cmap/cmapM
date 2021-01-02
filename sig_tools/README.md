
# Mortar Matlab Library

Mortar is a custom library that provides MATLAB&reg; routines to process, analyze and visualize Connectivity Map (CMap) data. To learn more about the CMap project at the Broad Institute, please visit [clue.io](https://clue.io).

**Note**: This is a private repository that contains code under active development and includes unpublished algorithms. Periodically a subset of the routines are made publicly available via the [cmapM](https://github.com/cmap/cmapM) repository. 

## Usage:

* To checkout a local copy of Mortar, use:

	``` 
	git clone https://github.com/cmap/mortar.git
	```

* To use Mortar within a Matlab session, type the following in the Matlab console:

	```
	if ~isdeployed
		MORTARPATH = '/path/to/mortar';
   		run (fullfile(MORTARPATH, 'util/usemortar'));
    end
    ```

* To automatically include Mortar on startup, add the above lines to
your default startup.m file. On unix-like systems this file is located at`~/matlab/startup.m`. For MacOS the startup.m file is in the`~/Documents/MATLAB`folder. You might also need to set the following environment variables prior to starting Matlab:

	```
	MATLABPATH=/path/to/startup.m
	MATLAB_USE_USERPATH=1
	```

* If new subfolders are created in Mortar, the path needs to be
refreshed by running:`usemortar`

* To remove the Mortar library from the search path, type:`unusemortar`

## Documentation:
http://www.broadinstitute.org/icmap/mortar_doc/index.html

**To regenerate the documentation run:**

```
lib_path = mortarpath;
html_path = '/path/to/mortar_docs';
addpath(fullfile(mortarpath, 'ext', 'm2html'));
gendoc(lib_path, html_path);

% Note: ensure graphviz is installed if the graph option of m2html is enabled
```

## Command line tools (SigTools)

Several commonly used analysis tools have been compiled into command-line binaries that can be executed directly from the command line without requiring Matlab. An advantage of using the tools in this manner is that they can be run without knowledge of Matlab and requiring a licence. In addition multiple jobs can be executed at once in the cloud or via a load-sharing facility like LSF or SGE.

Docker images for each SigTool are available via [Docker Hub](https://hub.docker.com/search?q=sig_&type=image) and documentation is viewable [here](https://cmap.github.io/cmap-sig-tools)

**Configuration of command line tools on Broad systems**

1. Add /cmap/tools/sig_tools/bin to your unix path. For bash shells add the following to ~/.my.bashrc

   ```
   export PATH=/cmap/tools/sig_tools/bin:$PATH
   ```	

2. Use the run matlab utility (`rum`) to execute the sig_tools. For example to run the SigPCA tool on a dataset, type:

   ```
   rum sig_pca_tool --ds 'raw_data.gctx'
   	```

## Contributors:
- Anup Jonchhe
- Ben Wedin
- Brian Geier
- Corey Flynn
- David Wadden
- Desiree Davison
- Lev Litichevskiy
- Marek Orzechowski
- Rajiv Narayan (Maintainer)
- Ted Natoli
