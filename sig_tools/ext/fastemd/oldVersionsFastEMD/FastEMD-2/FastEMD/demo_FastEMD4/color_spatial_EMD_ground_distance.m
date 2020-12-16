% [ground_distance_matrix]= color_spatial_EMD_ground_distance(im1,im2,alpha_color,threshold,coordinates_transformation)
%
% Creates an EMD ground distance matrix between im1 and im2 (ims
% should be in L*a*b* space). The distance between the pixels
% (x1,y1,L1,a1,b1) and (x2,y2,L2,a2,b2) is:
%  min(alpha_color*CIEDE2000(L1,a1,b1,L2,a2,b2) +
%      (1-alpha_color)*||(T(x1),T(y1))-(T(y2),T(y2))||_2 , threshold)
% Where T is a coordinate transformation determined by
% coordinates_transformation:
%  coordinates_transformation==1 Identity:
%   T(x1)=x1 T(y1)=y1
%   T(x2)=x2 T(y2)=y2
%  coordinates_transformation==2 Center:
%   T(x1)=x1-((size(im1,2)+1)/2) T(x2)=x2-((size(im2,2)+1)/2)
%   T(y1)=y1-((size(im1,1)+1)/2) T(y2)=y2-((size(im2,1)+1)/2)
%  coordinates_transformation==3 Normalized (coordinates are transformed
%  to [0 1]):
%   T(x1)=(x1-1)/(size(im1,2)-1) T(x2)=(x2-1)/(size(im2,2)-1)
%   T(y1)=(y1-1)/(size(im1,1)-1) T(y2)=(y2-1)/(size(im2,1)-1)
%
% Note 1: alpha_color*threshold should be smaller or equal to 20, as
% CIEDE2000 (like all other color distances) should be saturated (see
% ICCV paper)
%
% Note 2: the ground_distance_matrix contains values only between im1 and
% im2. That is, the distance between im1 pixels to themselves and
% im2 pixels to themselves are not computed. This means that the matrix
% can be used for EMD, but cannot be used for distances such as the
% Quadratic-Form (aka Mahalanobis).










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
