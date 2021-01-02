function [hd,hdict,desc] = dict2cell(dict)
% Usage: [HD,HDICT,DESC] = DICT2CELL(DICT)
% Input: a dictionary (a containers.map object
% Outputs:
%   HD: a cell array containing the dictionary keys
%   HDICT: a dictionary give the column of DESC corresponding to each entry in HD
%   DESC: A cell array containing the dictionary contents

hd = keys(dict)'; % the keys for the dictionary
hdict = list2dict(hd);
tmp = dict.values; % grab all the dictionary values
desc = [tmp{:}]; % put them in a single cell array