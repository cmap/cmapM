#!/bin/bash 
# Wrapper to execute R scripts on Broad servers
# using the R dotkit

# Uncomment to debug
#set -x

# setup virtual buffer
if [[ ! -e /tmp/.X0-lock ]];then
    XVFB_DISPLAY=0
    FONT_PATH='unix/:7100'
#    Xvfb :$XVFB_DISPLAY -fp $FONT_PATH -screen 0 1280x1024x24 2>/dev/null &
    Xvfb :$XVFB_DISPLAY -screen 0 1024x768x32 2>/dev/null &
    export DISPLAY=:$XVFB_DISPLAY
    XVFB_PID=$!
fi

eval `/broad/software/dotkit/init -b`
reuse -q R-3.2
reuse -q GCC-5.1

#if variable specifying location of R libraries is not set, set it to a reasonable default
if [[ -z $R_LIBS ]]
then
    export R_LIBS=/cmap/tools/opt/R-packages/R-3.2
fi

export R_DEFAULT_PACKAGES='graphics,grDevices,utils,roller'
echo "R binary:" $(which Rscript)
echo "R_LIBS:$R_LIBS"
echo "R_DEFAULT_PACKAGES:$R_DEFAULT_PACKAGES"
echo "DISPLAY:$DISPLAY"
echo ">>Executing: Rscript $@"
Rscript "$@"

# kill xvfb
if [[ -f "/proc/$XVFB_PID" ]]; then
    echo "kill -s SIGINT $XVFB_PID"
fi
