#!/bin/bash 
# Wrapper to execute python scripts on Broad servers
# using the custom CMAP python dotkit

# Uncomment to debug
#set -x
eval `/broad/software/dotkit/init -b`
reuse -q CMAP-Python-2.7.10
# Set custom PYTHONPATH externally if needed
echo "Python binary:"$(which python)
echo "Python path:$PYTHONPATH"
echo ">>Executing: python $@"
python "$@"
