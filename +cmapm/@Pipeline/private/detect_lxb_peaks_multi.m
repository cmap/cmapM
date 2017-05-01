function pkstats = detect_lxb_peaks_multi(rp1, rid, varargin)
% DETECT_LXB_PEAKS_MULTI Detect peaks for multiple analytes in lxb data.
%   PKSTATS = DETECT_LXB_PEAKS_MULTI(RP1, RID) detect peaks for all
%   analytes specified by nonzero entries in the grouping variable RID. RP1
%   is a 1d vector of fluorescent intensities. RID has the same dimension
%   as RP1. PKSTATS is a structure array with the detected peaks and
%   support information. The size of the array equals the number of
%   analytes specified by unique non-zero entries in RID.
%
%   PKSTATS = DETECT_LXB_PEAKS_MULTI(RP1, RID, 'Param1, 'Value1',...)
%   Specify optional parameters to peak detection routine.
%   analytes : string indicating valid analyte indices. Default is '1:500'
%   notduo : string indicating analyte indices to ignore. Default is '0'
%
%   Also see DETECT_LXB_PEAKS_SINGLE for description of peak calling
%   parameters.
%
% See: DETECT_LXB_PEAKS_SINGLE

pnames = {'analytes', 'notduo', 'showfig', 'rpt'};
dflts = { 1:500, '0', false, 'MYPLATE' };
arg = parse_args(pnames, dflts, varargin{:});
% nonduo analytes
arg.notduo = eval(arg.notduo);
analyte = intersect(arg.analytes, unique(rid(rid>0)));
nanalyte = length(analyte);
totanalyte = length(arg.analytes);
pkstats(1:totanalyte, 1) = struct('pkexp', 1,...
    'pksupport', 0, 'pksupport_pct', 0, 'pkheight', 0,...
    'totbead', 0, 'ngoodbead', 0,...
    'medexp', 1, ...
    'method','none');

% tag missing analytes
miss = setdiff(arg.analytes, analyte);
[pkstats(miss).method] = deal('missing');

for ii=1:nanalyte    
    % just report median for not duo analytes
    if ismember(analyte(ii), arg.notduo)
        pkstats(analyte(ii)) = detect_lxb_peaks_single(rp1(rid==analyte(ii)), 'ksmethod', 'median');
    else
        try
        pkstats(analyte(ii)) = detect_lxb_peaks_single(rp1(rid==analyte(ii)), varargin{:});
        catch e
            disp(e);
            fprintf('Analyte %d, count=%d\n', analyte(ii), nnz(rid==analyte(ii)));
        end
        if arg.showfig
            namefig(sprintf('%s_%d',arg.rpt, ii));
        end
    end
end

