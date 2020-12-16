#!/bin/bash

for i in *_ref.cc;
do
    cp ${i/_ref/} $i;
done
