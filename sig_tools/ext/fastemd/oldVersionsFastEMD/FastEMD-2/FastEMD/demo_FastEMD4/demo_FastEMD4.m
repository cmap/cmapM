% This demo loads two color images and efficiently computes the emd_hat
% between them. The ground distance is a thresholded linear combination of
% the spatial and color distance between pixels. This is similar to the
% distance I used for color images in my ICCV paper. Image sizes do not
% need to be the same. As a color distance I used CIEDE2000.
% emd_hat is described in the paper:
%  A Linear Time Histogram Metric for Improved SIFT Matching
%  Ofir Pele, Michael Werman
%  ECCV 2008
% The efficient algorithm is described in the paper:
%  Fast and Robust Earth Mover's Distances
%  Ofir Pele, Michael Werman
%  ICCV 2009
% CIEDE2000 is described in the papers:
% The development of the CIE 2000 colour-difference formula: CIEDE2000
%  M. R. Luo, G. Cui, B. Rigg
%  CRA 2001
% The CIEDE2000 color-difference formula: Implementation notes, supplementary test data, and mathematical observations
%  Gaurav Sharma, Wencheng Wu, Edul N. Dalal
%  CRA 2004

clc; close all; clear all;

addpath ../

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Distance parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% In the paper I used threshold=20, but I didn't use alpha_color and
% 1-alpha_color for the spatial. I just added them. So using threshold=10
% is equivalent to what I used in the paper.
threshold= 10;
alpha_color= 1/2;
% Center. In the ICCV paper center and identity were equivalent as the image
% sizes were the same.
coordinates_transformation= 2; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load images
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
im1= imresize( imread('1.jpg') , 1/30);
im2= imresize( imread('2.jpg') , 1/30);
% 3.jpg is more similar to 1.jpg and thus the running time will be longer.
%im2= imresize( imread('3.jpg') , 1/30);
im1_Y= size(im1,1);
im1_X= size(im1,2);
im1_N= im1_Y*im1_X;
im2_Y= size(im2,1);
im2_X= size(im2,2);
im2_N= im2_Y*im2_X;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EMD input
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
P= [ ones(im1_N,1)  ;  zeros(im2_N,1) ];
Q= [ zeros(im1_N,1) ;  ones(im2_N,1)  ];

im1= double(im1)./255;
im2= double(im2)./255;
cform = makecform('srgb2lab');
im1_lab= applycform(im1, cform);
im2_lab= applycform(im2, cform);

% Creating the ground distance matrix.
% Loops in Matlab are very time consuming, so I use mex.
% Matlab corresponding code is commented out below.
tic
[ground_distance_matrix]= color_spatial_EMD_ground_distance(im1_lab,im2_lab,...
                                                  alpha_color,threshold, ...
                                                  coordinates_transformation);
fprintf(1,'computing the ground distance matrix, time in seconds: %f\n', ...
        toc);
% $$$ ground_distance_matrix= ones(length(P),length(P)).*threshold;
% $$$ for i=1:length(P)
% $$$     ground_distance_matrix(i,i)=0;
% $$$ end
% $$$ i= 1;
% $$$ for x1=1:im1_X
% $$$     for y1=1:im1_Y
% $$$         j= 1;
% $$$         L1= im1(y1,x1,1);
% $$$         a1= im1(y1,x1,2);
% $$$         b1= im1(y1,x1,3);
% $$$         x1_normalized= x1/im1_X;
% $$$         y1_normalized= y1/im1_Y;
% $$$         
% $$$         
% $$$         for x2=1:im2_X
% $$$             for y2=1:im2_Y
% $$$                 L2= im2(y2,x2,1);
% $$$                 a2= im2(y2,x2,2);
% $$$                 b2= im2(y2,x2,3);
% $$$                 x2_normalized= x2/im2_X;
% $$$                 y2_normalized= y2/im2_Y;
% $$$                 
% $$$                 spatial_dist= sqrt( (x1_normalized-x2_normalized)^2 + ...
% $$$                                     (y1_normalized-y2_normalized)^2 );
% $$$                 
% $$$                 color_dist= deltaE2000( [L1,a1,b1], [L2,a2,b2]);
% $$$                                 
% $$$                 dist= (alpha_color)*color_dist + (1-alpha_color)*spatial_dist;
% $$$                 
% $$$                 dist= min([dist threshold]);
% $$$                 
% $$$                 ground_distance_matrix(i,im1_N+j)= dist;
% $$$                 ground_distance_matrix(im1_N+j,i)= dist;
% $$$                 
% $$$                 j= j+1;
% $$$             end
% $$$         end
% $$$         
% $$$         
% $$$         i= i+1;
% $$$     end
% $$$ end

% In ICCV paper extra_mass_penalty did not matter as image sizes were the same.
extra_mass_penalty= -1;
flowType= 3;

tic
[emd_hat_mex_val_with_flow F]= emd_hat_mex(P,Q,ground_distance_matrix,extra_mass_penalty,flowType);
fprintf(1,'Note that the ground distance here is not a metric.\n');
fprintf(1,'emd_hat_mex, time in seconds: %f\n',toc);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%






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


