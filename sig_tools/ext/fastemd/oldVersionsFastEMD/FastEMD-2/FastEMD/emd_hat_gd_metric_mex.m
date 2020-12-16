% [dist F]= emd_hat_gd_metric_mex(P,Q,C,extra_mass_penalty,FType)
%
% Fastest version of EMD. Also, in my experience metric ground distance
% yields better performance.
% 
% Output:
%  dist - the computed distance
%  F - the flow matrix, see "FType" 
%  Note: if it's not required it's computation is totally skipped.
%
% Required Input:
%  P,Q - two histograms of size N
%  C - the NxN matrix of the ground distance between bins of P and Q.
%  Must be a metric. I recommend it to be a thresholded metric (which
%  is also a metric, see ICCV paper).
%
% Optional Input:
%  extra_mass_penalty - the penalty for extra mass. If you want the
%                       resulting distance to be a metric, it should be
%                       at least half the diameter of the space (maximum
%                       possible distance between any two points). If you
%                       want partial matching you can set it to zero (but
%                       then the resulting distance is not guaranteed to be a metric).
%                       Default value is -1 which means 1*max(C(:)).
%  FType - type of flow that is returned. 
%          1 - represent no flow (then F should also not be requested, that is the
%          call should be: dist= emd_hat_gd...
%          2 - fills F with the flows between bins connected
%              with edges smaller than max(C(:)).
%          3 - fills F with the flows between all bins, except the flow
%              to the extra mass bin.
%          Defaults: 1 if F is not requested, 2 otherwise





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
