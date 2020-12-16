#Setup python shell environment
export PATH=/cmap/tools/python27/bin:${PATH}
export PYTHONPATH=/cmap/tools/pestle:/cmap/tools/python27/lib/python/:/cmap/tools/python27/lib/:/cmap/tools/python26/lib/python2.7/site-packages
export LD_LIBRARY_PATH=/cmap/tools/python27/lib/:/broad/software/free/Linux/redhat_5_x86_64/pkgs/hdf5_1.8.4/lib:$LD_LIBRARY_PATH
export WORKON_HOME=/cmap/tools/pyenv/
export LANG='en_US.utf8'
export LC_ALL='en_US.utf8'
source /cmap/tools/python27/bin/virtualenvwrapper.sh
workon py27_env