function [ts, dn] = get_timestamp(f)
% GET_TIMESTAMP Get Modification timestamp of files and folders.
%   [TS, DN] = GET_TIMESTAMP(F) Returns the timestamp and serial date
%   number for file or folder F. F can be a string or a cell array for full
%   paths to the file.
%
% See also: DATENUM

if ischar(f)
    f = {f};
end
nf = length(f);
ts = cell(nf, 1);
dn = zeros(nf, 1);
for ii=1:nf
    assert(isfileexist(f{ii}), 'File not found %s', f{ii})
    d = dir(f{ii});
    if isdir(f{ii})
        ts{ii} =  d(strcmp('.', {d.name})).date;
    else
        ts{ii} = d.date;
    end           
    dn(ii) = datenum(ts{ii});
end

end