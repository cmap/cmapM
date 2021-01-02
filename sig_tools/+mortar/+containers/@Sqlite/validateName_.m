function name = validateName_(obj, name)
% Check for valid SQL name and quote keywords
if ischar(name)
    name = {name};
end

isok = ~cellfun(@isempty, regexp(name,'^[a-zA-Z][a-zA-Z0-9_]*$'));
if all(isok)
    for ii=1:length(name)
        if obj.iskeyword(name{ii})
            % quote reserved words
            name{ii} = obj.keywords(upper(name{ii}));
        end
    end
else
    disp(name(~isok))
    error('Invalid names')
end
end