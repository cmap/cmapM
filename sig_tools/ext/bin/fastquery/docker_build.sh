#!/usr/bin/env bash

#change the version number for each new build
docker build -t cmap/fastquery_compile:latest -t cmap/fastquery_compile:v0.3 --rm=true .
