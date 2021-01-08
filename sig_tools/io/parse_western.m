function [ds, hd] = parse_western(fname)
% PARSE_WESTERN Parse in-cell western data.
%   [DS, HD] = PARSE_WESTERN(FNAME)
%   DS is a data structure with the 
%   following fields:
%       mat: Numeric data matrix [RxC]
%       rid: Cell array of row ids
%       rhd: Cell array of row annotation fieldnames
%       rdict: Dictionary of row annotation fieldnames to indices
%       rdesc: Cell array of row annotations
%       cid: Cell array of column ids
%       chd: Cell array of column annotation fieldnames
%       cdict: Dictionary of column annotation fieldnames to indices
%       cdesc: Cell array of column annotations
%       version: GCT version string
%       src: Source filename
%   HD is a structure containing header information.

fid = fopen(fname, 'rt');
line = fgetl(fid);

hd = [];
while isempty(regexp(line, '^\.\.', 'once'))
    kv = textscan(line, '%s%s','delimiter', '\t');
    fn = validvar(lower(kv{1}), '_');
    if ~isempty(kv{2})
        val = kv{2}{1};
    end
    hd.(fn{1}) = val;
    line = fgetl(fid);
end

line = fgetl(fid);
cid = textscan(line, '%s','delimiter','\t');
cid = cid{1}(2:end);
nc = length(cid);
fmt = ['%s',repmat('%f', 1, nc)];
data = textscan(fid, fmt,'delimiter','\t');
fclose(fid);

ds = mkgctstruct(cell2mat(data(2:end)), 'rid', data{1}, 'cid',cid);

end