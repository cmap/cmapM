#!/bin/env bash
# patch_mortar_html.sh
# Patch legacy HTML reports prior to asset change to analysis.clue.io

INPATH="${1:-PWD}"
find "$INPATH" -name '*.html' -exec sed -i 's#\(https*:\)*//cmap.github.io/cdn/#//analysis.clue.io/assets/#g' {} \;
