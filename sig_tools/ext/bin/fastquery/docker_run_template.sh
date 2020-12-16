#!/usr/bin/env bash
docker run --rm \
--name fastquery_compile \
-v /PATH/TO/MORTAR/:/cmap/mortar/ \
-it cmap/fastquery_compile
