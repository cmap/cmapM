function [] = demo_FastEMD_compute(P,Q,D,extra_mass_penalty,flowType)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EMD computation
% This part is common to all demo_FastEMD scripts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Fastest version - Exploits the fact that the ground distance is
% thresholded and a metric.
tic
emd_hat_gd_metric_mex_val= emd_hat_gd_metric_mex(P,Q,D,extra_mass_penalty);
fprintf(1,'emd_hat_gd_metric_mex time in seconds: %f\n',toc);
 
% A little slower - with flows
tic
[emd_hat_gd_metric_mex_val_with_flow F1]= emd_hat_gd_metric_mex(P,Q,D,extra_mass_penalty,flowType);
fprintf(1,'emd_hat_gd_metric_mex computing the flow also, time in seconds: %f\n', ...
        toc);

% Even slower - Only exploits the fact that the ground distance is
% thresholded
tic
emd_hat_mex_val= emd_hat_mex(P,Q,D,extra_mass_penalty);
fprintf(1,'emd_hat_mex time in seconds: %f\n',toc);

% Even slower - with flows
tic
[emd_hat_mex_val_with_flow F2]= emd_hat_mex(P,Q,D,extra_mass_penalty,flowType);
fprintf(1,'emd_hat_mex computing the flow also, time in seconds: %f\n',toc);

%  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  % Comparison with Rubner (much slower than my versions) -
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
%  D= double(D);
%  tic
%  emd_rubner_mex_val= (sumSmall*emd_mex(P',Q',D)) + (sumBig-sumSmall)*max(D(:));
%  fprintf(1,'emd_rubner_mex time in seconds: %f\n',toc);
%  
%  if (emd_hat_gd_metric_mex_val~=emd_rubner_mex_val)
%      fprintf(1,'emd_hat_gd_metric_mex_val - emd_rubner_mex_val == %f\n', ...
%              emd_hat_gd_metric_mex_val-emd_rubner_mex_val);
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