function tbl = parse_record_list(tbl_list, varargin)
% PARSE_RECORD_LIST Read list of tables into a stacked table
%   TBL = PARSE_RECORD_LIST(TBL_LIST) TBL_LIST is a cell array or GRP file containing 
%   filepaths to text delimited table files to read. TBL is a struct array
%   with records from each table. The fields in TBL is the union of fields 
%   from all tables.

tbl_paths_cell = parse_grp(tbl_list);
assert(~isempty(tbl_paths_cell), 'Table List is empty.')

% Parse each table into a cell array
num_tbl = length(tbl_paths_cell);
tbl_cell = cell(num_tbl, 1);

for ii = 1:num_tbl
    dbg(1, '# %d of %d', ii, num_tbl) 
    tbl_cell{ii} = parse_record(tbl_paths_cell{ii}, varargin{:});
    fn = fieldnames(tbl_cell{ii});
    if isequal(ii, 1)
        field_dict = mortar.containers.Dict(fn, 1:length(fn));
    else
        isk = field_dict(fn);
        k = fn(~isk);
        v = num2cell(find(~isk));
        field_dict.add(k, v);
    end    
end

all_fn = field_dict.sortKeysOnValue;

tbl = [];
for ii=1:num_tbl
    this_tbl = keepfield(tbl_cell{ii}, all_fn);
    tbl = [tbl; this_tbl];
end

end
