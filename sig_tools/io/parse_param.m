function p = parse_param(paramfile)
% PARSE_PARAM Parse a parameters file.
%   P = PARSE_PARAM(FNAME) returns a structure with fieldnames set to the
%   parameter names specified in FNAME.

if isfileexist(paramfile)
    fid = fopen(paramfile, 'rt');
    c = textscan(fid, '%s','delimiter', '\n', 'CommentStyle', '#', 'headerlines', 1);
    c = c{1}(~cellfun(@isempty, strtrim(c{1})));
    fclose (fid);
    np = length(c);
    for ii=1:np
        [~, tok] = regexp(c{ii}, '^([\!{}\[\]\w\s'']+):(.*)', 'match', 'tokens');
        num = str2double(tok{1}{2});
                
        if strncmp('!', tok{1}{1}, 1)            
            % logical
            if ~isnan(num)
                val = abs(num)>0;
            else 
                val = ismember(lower(strtrim(tok{1}{2})),...
                              {'1', 'true'});
            end                        
        elseif isnan(num) || strncmp('''', tok{1}{1}, 1)
            % string
            val = strtrim(tok{1}{2});
        else
            val=num;
        end
        
        if strncmp('{', tok{1}{1},1)
            % cell array
            val = tokenize(val, ',', true);
        elseif strncmp('[', tok{1}{1},1)
            % numeric array
            val = textscan(tok{1}{2}, '%f',...
                    'delimiter', {',','\t',' ',';'},...
                    'multipledelimsasone',true);
            if ~isempty(val)
                val = val{1};
            else
                val = [];
            end            
        end
        key = validvar(tok{1}{1}); 
        p.(key{1}) = val;
    end
else
    error('File not found %s', paramfile)
end
end