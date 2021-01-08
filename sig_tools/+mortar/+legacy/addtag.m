function modtag = addtag(tag, newtag, newval)
% ADDTAG Add a key/value tag to existing tag string

switch class(tag)
    case 'cell'
        info = tags2info(tag);
        info.(newtag) = newval(:);
        modtag = info2tags(info);
    case 'containers.Map'
        modtag = tag;
        modtag(newtag) = newval;
end