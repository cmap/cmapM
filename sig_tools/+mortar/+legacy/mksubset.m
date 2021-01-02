% MKSUBSET Create a subset of a matlab gene expression dataset 
% [GE,GN,GD,SID,missing] = mksubset(fullset, fname, sname,outfile)
% 
% INPUTS:
% fullset   : file name of full dataset (mat file or .gct file), string
%               OR a structure with the following fields [ge,gn,gd,sid]
% fname     : cell array of features to include in subset
%             use [] to retain all features
% sname     : cell array of sample ids to include in subset
%             use [] to retain all samples
% outfile   : output file name (optional), string
% 
% OUTPUTS:
% GE        : gene expression matrix, double
% GN        : feature labels, cell array
% GD        : description of features, cell array
% SID       : sample names
% missing   : list of features and sample ids that were in the 
%              include lists but missing from the full dataset

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

function [GE,GN,GD,SID,missing] = mksubset(fullset, fname, sname,varargin)

pnames = {'-precision', '-outfile', '-saveasmat'};
dflts =  { 4, '', false };
[eid, emsg, midx, PRECISION, outfile, saveasmat] = ...
    getargs(pnames, dflts, varargin{:});

if isstruct(fullset)
    GE = fullset.ge;
    GN = fullset.gn;
    GD = fullset.gd;
    SID = fullset.sid;
else
    [p,f,ext] = fileparts(fullset);

    if strmatch('.gct',lower(ext))
        [GE,GN,GD,SID] = parse_gct0(fullset);
    else
        %load full dataset (GE,GN,GD,SID)
        load(fullset);
    end
end

%keep data for specified features (rows)
if ~isempty(fname)
    
    [sortint,ia,ib] = intersect(GN,fname);   
    %sort the indices to keep original order
    [sb,iib]=sort(ib);
    idx=ia(iib);
    
    GN = GN(idx);
    GE = GE(idx,:);
    GD = GD(idx);
    %list of missing features
    missing.fname = setdiff(fname,GN);

else
    missing.fname = [];
end

%keep data for specified samples (columns)
if ~isempty(sname)

    [sortint,ia,ib] = intersect(SID,sname);
    [sb,iib]=sort(ib);
    idx=ia(iib);    
    GE=GE(:,idx);
    SID = SID(idx);
    missing.sname = setdiff(sname,SID);
    
else
    
    missing.sname = [];
end

if ~isempty(outfile)
    if ~isempty(GE)
        if saveasmat
            save (outfile,'GE','GN','GD','SID');
        else
            mkgct0(outfile, GE, GN, GD, SID, PRECISION);
        end
    else
        fprintf ('Empty matrix, skipping\n');
    end
end
