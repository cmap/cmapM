% TAGS2DICT Parse luminex tag strings.
% S = TAGS2INFO(T) returns a dictionary with the tag names and values as
% key/value pairs.

function s = tags2dict(t, varargin)

%tokenize tags
x = tokenize(regexprep(t,'\|$',''), '|');
nrec = length(x);
s = containers.Map();
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
                s(name{ii}) = vals;
            else
                s(name{ii}) = cellfun(@(x) x{ii}, x, 'uniformoutput', false);
            end
        end
    end
end