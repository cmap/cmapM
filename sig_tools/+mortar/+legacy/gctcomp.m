function [issame, rmsd] = gctcomp(ds1, ds2, varargin)
% GCTCOMP Compare two GCT data structures.
%   [ISSAME, RMSD] = GCTCOMP(DS1, DS2) Compares GCT structures DS1 and DS2
%   adjusting for row and column ordering. ISSAME is true if the data
%   matrices of DS1 and DS2 differ by an RMSD of less than eps. If the DS1
%   and DS2 do not have comparable row or column annotations, then RMSD is
%   set to Inf.
%
%   [ISSAME, RMSD] = GCTCOMP(DS1, DS2, param1, value1,...) specify optional
%   parameters:
%   'tol':  scalar double, accepted tolerance to determine if matrices
%           differ. ISSAME = RMSD < TOL

%TODO add comparison of metadata fields

pnames = {'tol'};
dflts = {eps};
args = parse_args(pnames, dflts, varargin{:});

[nr1, nc1] = size(ds1.mat);
[nr2, nc2] = size(ds2.mat);

issame = false;
rmsd = inf;

if isequal(nr1, nr2) && isequal(nc1, nc2)
    [~, cidx2] = intersect_ord(ds2.cid, ds1.cid);
    [~, ridx2] = intersect_ord(ds2.rid, ds1.rid);
    if isequal(length(cidx2), nc1) && isequal(length(ridx2), nr1)
        rmsd = rmse(ds1.mat, ds2.mat(ridx2, cidx2));
        issame = rmsd < args.tol;
    end    
end

%meta data
%Rows
cmn_rdict = intersect(ds1.rdict.keys, ds2.rdict.keys);
if ~isequal(length(cmn_rdict), ds1.rdict.length)
    fprintf ('Row metadata field do not match!\n')
    fprintf('Extra fields in DS1:\n')
    setdiff(ds1.rdict.keys, cmn_rdict)
    fprintf('Extra fields in DS2:\n')
    setdiff(ds2.rdict.keys, cmn_rdict)
end

%Columns
cmn_cdict = intersect(ds1.cdict.keys, ds2.cdict.keys);
if ~isequal(length(cmn_cdict), ds1.cdict.length)
    fprintf ('Column metadata fields do not match!\n')
    fprintf('Extra fields in DS1:\n')
    setdiff(ds1.cdict.keys, cmn_cdict)
    fprintf('Extra fields in DS2:\n')
    setdiff(ds2.cdict.keys, cmn_cdict)
end

end