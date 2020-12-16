function prefix = brd_prefix(brd_id)
% BRD_PREFIX Strip batch information from BRD ids. 
%   PREFIX = BRD_PREFIX(BRD_ID)

if ischar(brd_id)
    brd_id = {brd_id};
end

prefix = brd_id;
is_brd = strncmpi('BRD-', brd_id, 4);
prefix(is_brd) = cellfun(@(x) sprintf('%s-%s',...
    x{1:min(length(x),1)}, x{2:min(length(x),2)}),...
    tokenize(brd_id(is_brd), '-'), 'uniformoutput',false);

end