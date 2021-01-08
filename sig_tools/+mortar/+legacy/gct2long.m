function [tbl, tblhd] = gct2long(ds, varargin)
% GCT2LONG convert gct dataset to long form.
% [TBL, TBLHD] = GCT2LONG(DS)

pnames = {'measure_id'};
dflts = {'Value'};
args = parse_args(pnames, dflts, varargin{:});

[nr, nc] = size(ds.mat);
nrdesc = length(ds.rhd);
ncdesc = length(ds.chd);
% annotations + rid + cid + value
ncol = nrdesc + ncdesc + 3;
nrow = nr*nc;

tblhd = [{'cid'}; ds.chd; {'rid'}; ds.rhd; {args.measure_id}];
tbl = [reshape(repmat([ds.cid, ds.cdesc],1, nr)', ncdesc+1, nc*nr)',...
repmat([ds.rid, ds.rhd], nc, 1),...
num2cell(ds.mat(:))];

end
