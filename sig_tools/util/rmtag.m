% RMTAG Remove a key/value tag from existing tag string

function modtag = rmtag(tag, newtag)

info = tags2info(tag);
if ischar(newtag)
   newtag={newtag};
end
for ii=1:length(newtag)
    if any(strcmp(newtag{ii}, fieldnames(info)))
        info = rmfield(info, newtag{ii});
    end
end
modtag = info2tags(info);