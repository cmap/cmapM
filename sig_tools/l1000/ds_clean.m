function ds = ds_clean(ds, varargin)

pname = {'row_field', 'col_field', 'exclude_row', 'exclude_col', 'cid2well'};
dflts = {'', '', true, true, true};

args = parse_args(pname, dflts, varargin{:});

ds = parse_gctx(ds);

if ~isempty(args.row_field)
  args.row_field = parse_grp(args.row_field);
else
  args.row_field = ds.rhd;
end

if ~isempty(args.col_field)
  args.col_field = parse_grp(args.col_field);
else
  args.col_field = ds.chd;
end

if ~args.exclude_col
  args.col_field = setdiff(ds.chd, args.col_field);
end
if ~args.exclude_row
  args.row_field = setdiff(ds.rhd, args.row_field);
end

ds = ds_delete_meta(ds, 'row', args.row_field);
ds = ds_delete_meta(ds, 'column', args.col_field);

if args.cid2well
  ds.cid = get_wellinfo(ds.cid);
end

end
