function tbl = gct2long_struct(ds, varargin)
% GCT2LONG convert gct dataset to a structure array in long form.
% [TBL, TBLHD] = GCT2LONG_struct(DS)

pnames = {'measure_id'};
dflts = {'Value'};
args = parse_args(pnames, dflts, varargin{:});

[nr, nc] = size(ds.mat);
ncdesc = length(ds.chd);

tblhd = [{'cid'}; ds.chd; {'rid'}; ds.rhd; {args.measure_id}];
tbl = cell2struct(...
    [reshape(repmat([ds.cid, ds.cdesc],1, nr)', ncdesc+1, nc*nr)',...
    repmat([ds.rid, ds.rdesc], nc, 1),...
    num2cell(ds.mat(:))], tblhd, 2);

end
