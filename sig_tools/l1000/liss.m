function [raw, qcrpt, cal, cidx_fail] = liss(raw, calib, ref, varargin)
% LISS  Perform invariant set scaling on Luminex 1000-plex data.
%   [SC, QCRPT, CALMAT, CIDX_FAIL] = LISS(RAW, CALIB, REF, PARAM)
%
%   Inputs:
%   RAW - GCT structure, Log2 gene expression. 
%   CALIB - GCT structure, Log2 Median expression of calibrator genes [calib levels x samples]
%   REF - vector, Reference expression of calibrator gene levels.
%   PARAM - Parameters
%       fitmodel: model type {'linear', 'power'}
%       minval: minimum threshold for scaled expression 
%       maxval: max threshold for scaled expression
%
%   Outputs:
%   SC - Normalized data set. Same structure and dimensions as RAW
%   QCRPT - Samplewise quality metrics. GCT structure.
%   CALMAT - Smoothed calibration curves. GCT structure.
%   CIDX_FAIL - Column indices of samples that failed normalization.
%
% Copyright 2009 by The Broad Institute.
%  
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or (at
% your option) any later version.
% 
% This program is distributed in the hope that it will be useful, but
% WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
% General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%  $Author: Rajiv Narayan [narayan@broadinstitute.org]
%  $Date: Jul.8.2010 12:45:40 EDT

if (nargin < 3)
    help (mfilename);
    error ('Incorrect number of arguments.');
end

pnames = {'fitmodel', 'minval', 'maxval',...
          'precision', 'debug'};
dflts = {'power', 0, 15, ...
         4, false};
args = parse_args(pnames, dflts, varargin{:});

[~, numSamples ] = size(raw.mat);
numLevels = size(calib.mat, 1);
totLevels = numLevels + 3;

classname = class(raw.mat);
% y-observed values for each level
calmat = zeros(numSamples, totLevels, classname);
% calib curve used for fitting
cal_obs = zeros(numSamples, totLevels-2, classname);
% calib curve after fit
cal_fit = zeros(numSamples, totLevels-2, classname);

% sample desc
desc = raw.cid;
qcpass_idx = false(numSamples, 1);
% samplewise quality report of fits
qcrpt = struct('sample', raw.cid ,'qcpass', qcpass_idx,...
    'fittype', args.fitmodel);
tic

for ii = 1:numSamples
    yobs = zeros(totLevels,1);
    
    % robust baseline expression (1 percentile, black pt)
    yobs(1) = prctile (raw.mat(:,ii), 1);
    
    % non zero black pt needed for power fit
    yobs(1) = max(yobs(1), 1);    
    
    % calibrator expression 
    yobs(2:numLevels+1) = calib.mat(:, ii);
   
    % lowess smoothing
    yobs(:,1) = malowess(ref, yobs, 'span', 4, 'robust', true);

    % robust maximal expression (99th percentile, white pt)
    yobs(end) = max(prctile (raw.mat(:,ii), 99), yobs(end));  
    
    % check if calib curve meets minimal requirements for fitting
    % [no NaN's, no Inf's,  max of one zero]
    if (any(isnan(yobs)) || any(isinf(yobs)) || nnz(yobs) < length(yobs)-1)
        calmat(ii,:) = yobs;
        % flag as bad
        desc{ii} = sprintf('QC_FAIL:%d', sum(diff(yobs)<0));
        fprintf('QC_FAIL:Sample %d:%s:max=%2.2f, min=%2.2f, nnz=%d\n', ...
            ii, raw.cid{ii}, max(yobs), min(yobs), nnz(yobs))
        % save un-normalized sample
%         sc.mat(:,ii) = raw.mat(:,ii);
        raw.mat(:, ii) = 0;
        cobs = max(yobs(1:end-2), 1);
        cal_obs(ii,:) = cobs;
        % fit calib curve is same as observed
        cal_fit(ii,:) = cobs;
        qcrpt(ii).qcpass = false; 
        qcrpt(ii).calib_slope = cobs(end) / cobs(1);
        % slope in degrees
        qcrpt(ii).calib_slope_deg = atand(qcrpt(ii).calib_slope);
        qcrpt(ii).calib_span = cobs(end) - cobs(1);
        qcrpt(ii).rsquare = 0;
    else
        qcpass_idx(ii) = true;
        qcrpt(ii).qcpass = true;        
        calmat(ii,:) = yobs;
        x = max(raw.mat(:,ii), 1);
        
        % nonlinear fit requires non-zero data
        % Note the model ignores the white pts        
        cobs = max(yobs(1:end-2), 1);
        % store calib 
        cal_obs(ii,:) = cobs;
        % reference calib curve
        cal_ref(:,1) = ref(1:end-2);
        % perform linear fit for quality stats
        [wt, bint, ~, ~, stats] = regress(cal_ref, x2fx(cobs));
        qcrpt(ii).calib_slope = wt(2);
        qcrpt(ii).calib_slope_deg = atand(wt(2));
        qcrpt(ii).calib_span = cobs(end) - cobs(1);
        qcrpt(ii).calib_linfit_rsquare = stats(1);
        % -log10 p-value of F statistic
        qcrpt(ii).calib_linfit_logpval = -log10(stats(3));
        
       switch lower(args.fitmodel)
             
           case 'linear'
               % Linear least sq fit
               % y = a + bx
               y = x2fx(x) * wt;
               cal_fit(ii, :) = x2fx(cobs) * wt;
               % quality metrics
               qcrpt(ii).coef_a = wt(1);
               qcrpt(ii).coef_b = wt(2);
               qcrpt(ii).ci_a = print_dlm_line(num2cellstr(bint(1,:),...
                   'precision',2), 'dlm', ',');
               qcrpt(ii).ci_b = print_dlm_line(num2cellstr(bint(2,:),...
                   'precision',2), 'dlm', ',');
               qcrpt(ii).rsquare = stats(1);
               qcrpt(ii).f = stats(2);
               qcrpt(ii).f_logpval = -log10(stats(3));
                              
           case 'power'
               % Power model non-linear least sq fit
               % Requires the Curve Fitting Toolbox
               % fittype = a*x^b + c
               if license('test', 'curve_fitting_toolbox')
                   ft = fittype('power2');
                   % create fit obj
                   [fobj,gof] = fit(cobs, cal_ref, ft);
                   if args.debug && ~isempty(lastwarn)
                       fprintf ('%d. %s %s\n', ii, raw.cid{ii},lastwarn);
                   end
                   % apply model to data
                   y = feval(fobj, x);
                   % post-fit calibration curve
                   cal_fit(ii, :) = feval(fobj, cobs);
                   
                   % additional goodness of fit stats
                   gofstats = gof_stats(cal_ref, cal_fit(ii,:)', 3);                   
                   % coefficients
                   qcrpt(ii).coef_a = fobj.a;
                   qcrpt(ii).coef_b = fobj.b;
                   qcrpt(ii).coef_c = fobj.c;
                   % 95% Confidence intervals
                   ci = confint(fobj);
                   qcrpt(ii).ci_a = print_dlm_line(num2cellstr(ci(:,1),...
                       'precision',2), 'dlm', ',');
                   qcrpt(ii).ci_b = print_dlm_line(num2cellstr(ci(:,2),...
                       'precision',2), 'dlm', ',');
                   qcrpt(ii).ci_c = print_dlm_line(num2cellstr(ci(:,3),...
                       'precision',2), 'dlm', ',');
                   % stats
                   qcrpt(ii).rsquare = gof.rsquare;
                   qcrpt(ii).adjrsquare = gof.adjrsquare;
                   qcrpt(ii).rmse = gof.rmse;
                   qcrpt(ii).f = gofstats.F;
                   qcrpt(ii).f_logpval = -log10(gofstats.pvalue + eps);
               else
                   error('Power fit requires the Curve Fitting Toolbox');
               end
           otherwise
               error('Unknown fitfun:%s', args.fitmodel)
       end
       
       % cutoff for thresholding data
       blackpt = args.minval;
       whitept = args.maxval;
       % maintain rank ordering of thresholded genes
       top = y >= whitept;
       bot = y <= blackpt;
       minres = 1/(10 ^ args.precision);       
       y(top) = whitept + minres*rankorder(y(top), 'direc', 'ascend',...
           'zeroindex', true);
       y(bot) = blackpt - minres*rankorder(y(bot), 'direc', 'descend',...
           'zeroindex', true);       
       qcrpt(ii).truncated_genes = nnz(top) + nnz(bot);       
       qcrpt(ii).median = median(y);       
       % iqr of profile on linear scale
       qcrpt(ii).iqr = pow2(iqr(y));
       % iqr of raw profile
       qcrpt(ii).iqr_raw = iqr(x);
       
       % Quantiles of the profile
       qtile = pow2(prctile(y, [1,25,75,99]));
       qcrpt(ii).q1 = qtile(1);
       qcrpt(ii).q25 = qtile(2);
       qcrpt(ii).q75 = qtile(3);
       qcrpt(ii).q99 = qtile(4);
       
       raw.mat(:, ii) = y;
            
    end
    if ~mod(ii,100) 
        fprintf ('%2.0f%% (%d/%d)\n', 100*ii/numSamples, ii, numSamples);
    end
end

cal = mkgctstruct(calmat,...
    'rid', raw.cid,...
    'rhd', {'DESC'},...
    'rdesc', desc,...
    'cid', ['BASE'; calib.rid; 'MOVAVG_1';'MOVAVG_2']);

fprintf ('Normalization complete.\nSamples passed qc: %d/%d\n',...
    nnz(qcpass_idx), numSamples);

cidx_fail = find(~qcpass_idx);

toc
