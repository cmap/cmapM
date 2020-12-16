% This demo efficiently computes emd_hat between two random SIFTs
% histograms (3d histograms, see Lowe's paper: "Distinctive image
% features from scale-invariant keypoints" for more detail) where the
% ground distance between the bins is the thresholded sum of orientation and
% spatial distanced.
% emd_hat was described in the paper:
% A Linear Time Histogram Metric for Improved SIFT Matching
% Ofir Pele, Michael Werman
%  ECCV 2008
% The efficient algorithm is described in the paper:
%  Fast and Robust Earth Mover's Distances
%  Ofir Pele, Michael Werman
%  ICCV 2009

clc; close all; clear all;
rand('state',sum(100*clock));

XNBP= 4; % SIFT's X-dimension
YNBP= 4; % SIFT's Y-dimension
NBO= 16; % SIFT's Orientation-dimension
N= XNBP*YNBP*NBO;
thresh= 2;
extra_mass_penalty= -1; % Default of maximum distance
flowType= 3; % Regular flows

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SIFT ground distance matrix computation.
% Note: loops in Matlab are costly.
% However, this should be done only once.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
D= zeros(N,N);
i= 1;
for y1=1:YNBP
    for x1=1:XNBP
        for nbo1=1:NBO
            
            j= 1;
            for y2=1:YNBP
                for x2=1:XNBP
                    for nbo2=1:NBO
                        D(i,j)= (sqrt((y1-y2)^2 + (x1-x2)^2) + ...
                                 min( [abs(nbo1-nbo2) NBO-abs(nbo1-nbo2)] ));
                        
                        j=j+1;
                    end
                end
            end
            i= i+1;
            
        end
    end
end
maxDist= max(D(:));
D= min(D,thresh);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
P= rand(N,1);
Q= rand(N,1);

% The demo includes several ways to call emd_hat_mex and emd_hat_gd_metric_mex
demo_FastEMD_compute(P,Q,D,extra_mass_penalty,flowType);

% Copyright (2009-2010), The Hebrew University of Jerusalem.
% All Rights Reserved.

% Created by Ofir Pele
% The Hebrew University of Jerusalem

% This software is being made available for individual non-profit research use only.
% Any commercial use of this software requires a license from the Hebrew University
% of Jerusalem.

% For further details on obtaining a commercial license, contact Ofir Pele
% (ofirpele@cs.huji.ac.il) or Yissum, the technology transfer company of the
% Hebrew University of Jerusalem.

% THE HEBREW UNIVERSITY OF JERUSALEM MAKES NO REPRESENTATIONS OR WARRANTIES OF
% ANY KIND CONCERNING THIS SOFTWARE.

% IN NO EVENT SHALL THE HEBREW UNIVERSITY OF JERUSALEM BE LIABLE TO ANY PARTY FOR
% DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST
% PROFITS, ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF
% THE THE HEBREW UNIVERSITY OF JERUSALEM HAS BEEN ADVISED OF THE POSSIBILITY OF
% SUCH DAMAGE. THE HEBREW UNIVERSITY OF JERUSALEM SPECIFICALLY DISCLAIMS ANY
% WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
% MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED
% HEREUNDER IS ON AN "AS IS" BASIS, AND THE HEBREW UNIVERSITY OF JERUSALEM HAS NO
% OBLIGATIONS TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
% MODIFICATIONS.
