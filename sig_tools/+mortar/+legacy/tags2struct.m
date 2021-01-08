% TAGS2INFO Parse luminex tag strings.
% S = TAGS2INFO(T) returns a structure containing tag values and tag names
% as fields.

function s = tags2struct(t, varargin)
if ischar(t)
    t = {t};
end
%tokenize tags
x = tokenize(regexprep(t,'\|$',''), '|');
nrec = length(x);
s = [];
% at least one record
if nrec>0
    ntag = length(x{1});
    if ntag>0
        hasequal = ~isempty(cell2mat(strfind(x{1},'=')));
        name = cell(ntag,1);
        withname = ~cellfun(@isempty,strfind(x{1},'='));
        noname = find(~withname);
        lastname='name';
        for ii=1:length(noname)
            name{noname(ii)} = lastname;
            lastname = sprintf('name_%d',ii+1);
        end
        if hasequal
            rawname = cellfun(@(x) x{1}, tokenize(x{1}, '=', 1), 'uniformoutput', false);
            name(withname) = rawname(withname);
        end
        for ii=1:ntag
            if withname(ii)
                vals = cellfun(@(x) x{2}, tokenize(cellfun(@(x) x{ii}, x, 'uniformoutput', false),'=', 1), 'uniformoutput', false);
                [s(1:nrec,1).(name{ii})] = vals{:};
            else
                vals = cellfun(@(x) x{ii}, x, 'uniformoutput', false);
                [s(1:nrec,1).(name{ii})] = vals{:};
            end
        end
    end
end