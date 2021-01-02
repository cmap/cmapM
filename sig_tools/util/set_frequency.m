function [freq_tbl, num_set, bm] = set_frequency(s)
% SETFREQ Count the occurrence of each set member
%   [T, N, BM] = SETFREQ(S) counts the frequency of occurrence of each 
%   member of sets defined by S. Returns a structure array T of length
% equal to N, the number of unique members of all sets, and BM a binary
% matrix in GCT format indicating the membership of a given feature in each
% set The structure T contains the following fields:
%   'rid' : feature identifier
%   'freq' : number of sets containing the feature 
%   'pct_freq' : frequency expressed as a percentage of the number of sets
%                in S

s = parse_geneset(s);

% convert set to binary matrix
bm = set2ds(s);
% frequency of occurrence of each feature
freq = sum(bm.mat, 2);
num_set = size(bm.mat, 2);
pct_freq = 100 * freq / num_set;
bm = ds_add_meta(bm, 'row', 'freq', num2cell(freq));
bm = ds_add_meta(bm, 'row', 'pct_freq', num2cell(pct_freq));
[~, ord] = sort(freq, 'descend');
bm = ds_slice(bm, 'ridx', ord);
freq_tbl = gctmeta(bm, 'row');

end

% function freq_ds = set_frequency(set_struct)
% % SET_FREQUENCY Frequency of occurrence of set members
% %   F = SET_FREQUENCY(S) computes frequency of occurrence of the union of
% %   elements in sets contained in the set structure S and returns a gct
% %   structure F with frequency and percent frequency of each unique
% %   element.
% 
% set_struct = parse_geneset(set_struct);
% feature_space = setunion(set_struct);
% lut = mortar.containers.Dict(feature_space);
% idx = lut(cat(1, set_struct.entry));
% 
% nset = length(set_struct);
% freq = accumarray(idx, ones(size(idx)));
% pct_freq = 100*freq/nset;
% freq_ds = mkgctstruct([freq, pct_freq], 'rid', feature_space,...
%                       'cid', {'freq'; 'pct_freq'});
% 
% end