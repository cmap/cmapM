#!/bin/bash
# Update production code folders
folders='/cmap/tools/mortar'

for f in $folders; do
    echo Updating $f...
    (cd $f; git pull)
done

