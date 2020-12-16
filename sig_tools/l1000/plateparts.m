function pp = plateparts(p)
% PLATEPARTS Split L1000 platename to components.
%   PP = PLATEPARTS(P) Returns a structure with the components of the
%   plates P. P can be a string or a cell array.
%   

if ischar(p)
    p = {p};
end
assert(iscell(p), 'Plates should be a string or cell array');
tok = tokenize(p, '_');

pp = struct('plate', p,...
       'pert_plate', '',...
       'cell_id', '',...
       'pert_time', '',...
       'rep_id', '',...
       'bset_batch', '',...
       'det_mode', '',...
       'brew_id', '',...
       'project_id', '');

parts = {'pert_plate', 'cell_id', 'pert_time', 'rep_id', 'bset_batch', 'det_mode'};

% check if number of tokens is valid
tok_len = cellfun(@length, tok);
assert(all(tok_len>=5), 'plate named should have at least 5 tokens');

% add default det mode if missing
miss_det = tok_len==5;
tok(miss_det) = cellfun(@(x) [x; {'DUO52HI53LO'}], tok(miss_det),...
                'uniformoutput', false);

for ii=1:length(parts)    
    val = cellfun(@(x) x{ii}, tok, 'uniformoutput', false);
    [pp.(parts{ii})] = val{:};
end

% brew identifier
brew_id = weld('_', {pp.pert_plate}',{pp.cell_id}',{pp.pert_time}');
[pp.brew_id] = brew_id{:};

% project id
project_id = regexprep({pp.pert_plate}', {'\..*$', '[0-9]*$'}, '');
[pp.project_id] = project_id{:};

end


