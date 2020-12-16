% ADDTAG Add a key/value tag to existing tag string

function modtag = updatetag(tag, newtag, newval)

info = tags2info(tag);
info.(newtag) = newval(:);
modtag = info2tags(info);