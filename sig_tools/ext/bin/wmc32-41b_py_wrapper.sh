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
#export PATH=/usr/local/bin:$PATH
export DYLD_LIBRARY_PATH=/usr/local/opt/openssl/lib:/usr/local/opt/sqlite/lib:/usr/local/lib:$DYLD_LIBRARY_PATH
export PYTHONPATH=~/workspace/pestle:$PYTHONPATH
#source ~/pyenv/python-2.7.10/bin/activate
source ~/pyenv/python-2.7.13/bin/activate
echo ">>Executing: python $@"
which python
python "$@"
