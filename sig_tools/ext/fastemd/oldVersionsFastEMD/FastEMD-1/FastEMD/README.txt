Code for emd_hat
----------------
Ofir Pele and Michael Werman 
Contact: ofirpele@cs.huji.ac.il
Version: 1.0, Jul 2009

This directory contains the source code for computing emd_hat or regular emd efficiently. 

See the web page at 
http://www.cs.huji.ac.il/~ofirpele/FastEMD/

Please cite these papers if you use this code:
 A Linear Time Histogram Metric for Improved SIFT Matching
 Ofir Pele, Michael Werman
 ECCV 2008
bibTex:
@INPROCEEDINGS{Pele-eccv2008,
author = {Ofir Pele and Michael Werman},
title = {A Linear Time Histogram Metric for Improved SIFT Matching},
booktitle = {ECCV},
year = {2008}
}
 Fast and Robust Earth Mover's Distances
 Ofir Pele, Michael Werman
 ICCV 2009
@INPROCEEDINGS{Pele-iccv2009,
author = {Ofir Pele and Michael Werman},
title = {Fast and Robust Earth Mover's Distances},
booktitle = {ICCV},
year = {2009}
}

The current version (1.0) is almost the same as the one used in the paper.

Easy startup
------------
Within Matlab:
>> demo_FastEMD

Compiling (the folder contains compiled binaries, thus you might not have to compile)
-------------------------------------------------------------------------------------
Within Matlab:
>> compile_FastEMD
In a linux shell:
>> make

Usage within Matlab
------------------- 
Type "help emd_hat_metric_mex" or "emd_hat_mex" in Matlab.

Usage within C++
----------------
See "emd_hat_metric.hxx" and "emd_hat.hxx"

Tips
----
The speed increase with smaller thresholds. In my experience the performance usually increases with
the threshold until a maximum and then it starts to decrease.
It seems that setting alpha in emd_hat to 1 which is equivalent to setting extra_mass_penalty to
the maximum possible ground distance gives best results. This is the default in all functions.

Computing regular EMD
---------------------
You'll need to set extra_mass_penalty to 0 and to divide the result by the minimum of the sums of
the histograms. I do not recommend to do it as the accuracy usually decreases.

Licensing conditions
--------------------
This software is made available for non-profit research purposes only.
It is necessary to obtain a license from the Hebrew University of Jerusalem for
commercial applications. See the file LICENSE.txt in this directory for conditions
of use.
