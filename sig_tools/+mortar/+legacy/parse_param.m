function p = parse_param(paramfile)
% PARSE_PARAM Parse a parameters file.
%   P = PARSE_PARAM(FNAME) returns a structure with fieldnames set to the
%   parameter names specified in FNAME.

if isfileexist(paramfile)
    fid = fopen(paramfile, 'rt');
    c = textscan(fid, '%s','delimiter', '\n', 'headerlines', 1);
    fclose (fid);
    np = length(c{1});
    % skip first line
    for ii=1:np
        [~, tok] = regexp(c{1}{ii}, '^(\w+):(.*)', 'match', 'tokens');
        num = str2double(tok{1}{2});
        if isnan(num)
            val = strtrim(tok{1}{2});
        else
            val=num;
        end
        key = validvar(tok{1}{1}); 
        p.(key{1}) = val;
    end
else
    error('File not found %s', paramfile)
end
end