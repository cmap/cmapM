% This demo loads two grayscale images and efficiently computes the emd_hat
% between them. emd_hat was described in the paper:
%  A Linear Time Histogram Metric for Improved SIFT Matching
%  Ofir Pele, Michael Werman
%  ECCV 2008
% The efficient algorithm is described in the paper:
%  Fast and Robust Earth Mover's Distances
%  Ofir Pele, Michael Werman
%  ICCV 2009

clc; close all; clear all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load images
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
im1= imread('cameraman.tif');
im2= imread('rice.png');
im1= imresize(im1,1/8);
im2= imresize(im2,1/8);
R= size(im1,1);
C= size(im1,2);
if (~(size(im2,1)==R&&size(im2,2)==C))
    error('Size of images should be the same');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EMD input
% Each unit of gray-level (between 0 and 255) is a unit of mass, and the
% ground distance is a thresholded distance. This is similar to:
%  A Unified Approach to the Change of Resolution: Space and Gray-Level
%  S. Peleg and M. Werman and H. Rom
%  PAMI 11, 739-742
% The difference is that the images do not have the same total mass 
% and we chose a thresholded ground distance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
COST_MULT_FACTOR= 1000;
THRESHOLD= 3*COST_MULT_FACTOR;
cost_mat= zeros(R*C,R*C,'int32');
j= 0;
for c1=1:C
    for r1=1:R
        j= j+1;
        i= 0;
        for c2=1:C
            for r2=1:R
                i= i+1;
                cost_mat(i,j)= min( [THRESHOLD (COST_MULT_FACTOR*sqrt((r1-r2)^2+(c1-c2)^2))] );
            end
        end
    end
end

P= int32(im1(:));
Q= int32(im2(:));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EMD computation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Fastest version - Exploits the fact that the ground distance is
% thresholded and a metric.
tic
emd_hat_metric_mex_val= emd_hat_metric_mex(P,Q,cost_mat);
fprintf(1,'emd_hat_metric_mex time in seconds: %f\n',toc);
 
% A little slower - Only exploits the fact that the ground distance is
% thresholded
tic
emd_hat_mex_val= emd_hat_mex(P,Q,cost_mat);
fprintf(1,'emd_hat_mex time in seconds: %f\n',toc);

if (emd_hat_metric_mex_val~=emd_hat_mex_val)
	error('EMDs that were computed with different interfaces are different!');
end

%  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  % Comparison with rubner (much slower than my versions) -
%  % You'll need to:
%  %  1. download emd mex files from:
%  %     http://www.mathworks.com/matlabcentral/fileexchange/12936
%  %     To rubner_emd/
%  %  2. Increase MAX_SIG_SIZE and MAX_ITERATIONS in emd.h
%  %  3. Compile it
%  %  4. You might also need to use 'unlimit' as Rubner's version 
%  %     uses the stack.
%  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  
%  fprintf('\n');
%  addpath ('rubner_emd/');
%  P= double(P);
%  Q= double(Q);
%  sumBig=   max([sum(P(:)) sum(Q(:))]);
%  sumSmall= min([sum(P(:)) sum(Q(:))]);
%  cost_mat= double(cost_mat);
%  tic
%  emd_rubner_mex_val= (sumSmall*emd_mex(P',Q',cost_mat)) + (sumBig-sumSmall)*max(cost_mat(:));
%  fprintf(1,'emd_rubner_mex time in seconds: %f\n',toc);
%  
%  if (emd_hat_metric_mex_val~=emd_rubner_mex_val)
%      fprintf(1,'emd_hat_metric_mex_val - emd_rubner_mex_val == %f\n', ...
%              emd_hat_metric_mex_val-emd_rubner_mex_val);
%      fprintf(1,'Note that there might be a small difference due to ');
%  	fprintf(1,'differences between double and int. Also differences ');
%  	fprintf(1,'might happen because of MAX_ITERATIONS in emd.h too small.\n');
%  end

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
