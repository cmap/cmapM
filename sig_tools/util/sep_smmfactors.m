function [bio_factor,factor_sort] = sep_smmfactors(sid)
% SEP_SMMFACTORS Pulls of smm factor string from sid
% 
%   [bio_factor,factor_sort] = sep_smmfactors(sid) will return the
%   bio_factor sorted alphabetically and the indices of the sorted order.
%   The routine assumes that the sid is any string with '-biofactor_str'
%   attached to each sample. 
%   Inputs:
%       sid - 1 by # samples cell array, sample column labels
%   Outputs:
%       bio_factor - the appended factor label of each sample, dimensions
%       are consistent with sid. bio_factor is sorted alphabetically
%       factor_sort - the indices of the labels, after sorting
%       alphabetically
% 
%   example run: 
%       smm = parse_gct_multi('foo');
%       [bio_factor,factor_sort] = sep_smmfactors(smm.sid);
%       smm.ge = smm.ge(:,factor_sort); 
%       smm.sid = smm.sid(factor_sort);
% 
% see also run_smm_analysis, parse_gct
% 
% Author: Brian Geier, Broad 2010

bio_factor = cell(size(sid));
for i = 1 : length(sid)
    tmp = sid{i};
    ix = find(tmp=='-');
    bio_factor{i} = tmp(ix(end)+1:end);
end

[~,factor_sort]  = sort(bio_factor);
bio_factor = bio_factor(factor_sort);