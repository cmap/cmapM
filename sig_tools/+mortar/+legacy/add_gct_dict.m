function ds = add_gct_dict(ds)
% ADD_GCT_DICT Add dictionaries for GCT row and column headers.
%   DS = ADD_GCT_DICT(DS) Returns a structure with dictionaries of DS.rhd
%   and DS.chd 'rdict' and 'cdict' fields

ds.rdict = list2dict(ds.rhd);
ds.cdict = list2dict(ds.chd);
end