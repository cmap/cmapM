#!/bin/bash

mkdir -p ~/.ssh/

cp /cmap/mortar/ext/bin/fastquery/id_rsa* ~/.ssh/
cp /cmap/mortar/ext/bin/fastquery/gitconfig ~/.gitconfig

cp /cmap/mortar/ext/bin/fastquery/config ~/.ssh/

chmod 400 ~/.ssh/id_rsa

make clean 
make  

git add fastquery
git commit -m "compile fastquery C++ code"

git push

