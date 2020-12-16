#!/bin/bash 
# Wrapper to execute R scripts 
# Uncomment to debug
#set -x

echo "R binary:" $(which Rscript)
echo "R_LIBS:$R_LIBS"
echo "R_DEFAULT_PACKAGES:$R_DEFAULT_PACKAGES"
echo ">>Executing: Rscript $@"
Rscript "$@"
