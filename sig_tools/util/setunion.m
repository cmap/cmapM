function space = setunion(gset)
% SETUNION Get union of all members in a geneset.
%   U = SETUNION(S) returns the union of all sets S. S can be a geneset
%   structure or a file in any valid format supported by parse_geneset.

if ~isstruct(gset)
    gset = parse_geneset(gset);
end

% d = mortar.containers.Dict();
% for ii=1:length(gset)
%     d(gset(ii).entry)=num2cell(ii*ones(length(gset(ii).entry),1));
% end
% space = d.keys;


% space = unique(cat(1, gset.entry));
% I feel the need, the need for speed...
space = mortar.containers.Dict(cat(1, gset.entry)).keys;

end