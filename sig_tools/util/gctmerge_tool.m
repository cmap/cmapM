function combined  = gctmerge_tool(gct_1,gct_2, mergecols, ignore_rdesc)

% COMBINED = GCTMERGE_TOOL(gct_1, gct_2, mergecols, ignore_rdesc)
%    GCTMERGE_TOOL takes two gct structs and appends them either along the
%    row or column axis.  
%
%    Parameters:
%        - GCT_1: either a gct struct or a path to a gct/gctx file; can be null.  
%          If gct_1 is empty (e.g. an empty array), returns gct_2. 
%        - GCT_2: either a gct struct or a path to a gct/gctx file.
%        - mergecols: boolean, optional, default 1.  If true, requires the row fields (rhd, rid, rdesc)
%          to be identical between the two gct files.  Then the gct structs are appended columnwise.
%          If false, requires the column fields (chd, cid, cdesc) to be identical, and appends rowwise.
%        - ignore_rdesc: boolean, optional, default 0.  If true and mergecols is true, disregards
%          the requirement that the two rdescs match.  

if ischar(gct_1)
    gct_1 = parse_gctx(gct_1);
end
if ischar(gct_2)
    gct_2 = parse_gctx(gct_2);
end

if nargin < 3
    mergecols = 1;
end
if nargin < 4
    ignore_rdesc = 0;
end

if isempty(gct_1)
    combined = gct_2;
    return;
end

if isempty(gct_2)
    combined = gct_1;
    return;
end

if mergecols
    %Sanity checks
    if ~(isequal(gct_1.rid, gct_2.rid) ...
            && isequal(gct_1.rhd, gct_2.rhd) ...
            && ifelse(ignore_rdesc, 1, isequal(gct_1.rdesc, gct_2.rdesc)) ...
            && isequal(gct_1.chd, gct_2.chd))
        disp('Error: gct structs cannot be merged across columns');
        return;
    end
    
    %combine two gct files
    combined.mat = horzcat(gct_1.mat, gct_2.mat);
    combined.rid = gct_1.rid;
    combined.rhd = gct_1.rhd;
    combined.rdesc = gct_1.rdesc;
    combined.cid = vertcat(gct_1.cid, gct_2.cid);
    %combined.chd = vertcat(gct_1.chd, gct_2.chd);  do not use this; think about it
    combined.chd = gct_1.chd;
    combined.cdesc = vertcat(gct_1.cdesc, gct_2.cdesc);
    combined.version = '#1.3';
    combined.src = [gct_1.src '|' gct_2.src];
    combined.cdict = gct_1.cdict;
    combined.rdict = gct_1.rdict;
else
    %mergerows
    if ~(isequal(gct_1.cid, gct_2.cid) ...
            && isequal(gct_1.chd, gct_2.chd) ...
            && isequal(gct_1.cdesc, gct_2.cdesc) ...
            && isequal(gct_1.rhd, gct_2.rhd))
        disp('Error: gct structs cannot be merged across rows');
        return;
    end

    combined.mat = vertcat(gct_1.mat, gct_2.mat);
    combined.rid = vertcat(gct_1.rid, gct_2.rid);
    combined.rhd = gct_1.rhd;
    combined.rdesc = vertcat(gct_1.rdesc, gct_2.rdesc);
    combined.cid = gct_1.cid;
    combined.chd = gct_1.chd;
    combined.cdesc = gct_1.cdesc;
    combined.version = '#1.3';
    combined.src = [gct_1.src '|' gct_2.src];
    combined.cdict = gct_1.cdict;
    combined.rdict = gct_1.rdict;
end
