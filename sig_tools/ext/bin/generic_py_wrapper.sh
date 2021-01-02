#!/bin/bash 
# A simple wrapper to execute python scripts from Matlab
# To customize for your local host make a copy of this file and
# add the required setup commands e.g. loading a virtualenv
# Set the MORTAR_PYTHON_WRAPPER environment variable to point to the 
# wrapper file, either via a startup script or using the setenv command 
# within Matlab

# Uncomment to debug
#set -x
# Setup virtualenv if needed
echo ">>Executing: python $@"
python "$@"
