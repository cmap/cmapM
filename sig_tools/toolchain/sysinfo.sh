#!/bin/bash

uname -a
#is it 64 bit flags should contain lm ("long mode")
echo -n "CPU Flags: "
grep 'flags' /proc/cpuinfo|grep --color "lm" |head -1|sed 's/.*: //g'

#number of physical processors
echo -n "Number of physical processors: "
grep 'physical id' /proc/cpuinfo | sort | uniq | wc -l

# number of cores
echo -n "Number of cores: "
grep 'cpu cores' /proc/cpuinfo |head -1|sed 's/.*: //g'

# number of virtual processors
echo -n "Number of virtual processors: "
grep ^processor /proc/cpuinfo | wc -l

