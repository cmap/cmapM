function mkgdf(ofname, ds, isweighted, isdirected)
% MKGDF Save graph in the GUESS .gdf format 
% MKGDF(OFNAME, DS) Saves unweighted graph as OFNAME. DS is GCT structure of an NxN
% adjacency matrix (non-zero values are considered edges). Common
% annotations of the rows and columns are also saved.
%
% MKGDF(OFNAME, DS, ISWEIGHTED) Saves a weighted graph if ISWEIGHTED is
% true. Default is false.
%
% See: http://gephi.org/users/supported-graph-formats/gdf-format/

nin = nargin;
if nin <3 
    isweighted = false;
elseif nin<4
    isdirected = false;
elseif nin <2
    error('Insufficient numper of inputs');
end

[nr, nc] = size(ds.mat);
fid = fopen(ofname, 'wt');

% common attributes for rows and columns
[attr, iattr_col, iattr_row] = intersect(ds.chd, ds.rhd);
nattr = length(attr);

% node definition
fprintf(fid, 'nodedef>name INT,cid VARCHAR');
attr_type = cell(nattr, 1);
for ii=1:nattr
    isnum = all(isnumeric_type(ds.cdesc(:, ds.cdict(attr{ii}))));
    if isnum
        attr_type{ii} = 'DOUBLE';
    else
        attr_type{ii} = 'VARCHAR';
    end
    fprintf(fid, ',%s %s', attr{ii}, attr_type{ii});
end
fprintf(fid, '\n');

% node names
attr_is_char = strcmp('VARCHAR', attr_type);
% sanitized row ids
rid = singlequote(strrep(ds.rid, ',', ';'));
for ii=1:length(ds.rid)
    if nattr
        this_attr = ds.rdesc(ii, iattr_row);
        % quote and replace commas
        this_attr(attr_is_char) = strrep(singlequote(this_attr(attr_is_char)),',',';');
    else
        this_attr = {};
    end
    
    v = [num2cell(ii), rid(ii), this_attr];
    print_dlm_line(v, 'dlm', ',', 'fid', fid);
end

% for ii=1:length(ds.cid)
%     this_attr = ds.cdesc(ii, iattr_col);
%     this_attr(attr_is_char) = strrep(singlequote(this_attr(attr_is_char)),',',';'); 
%     v = [num2cell(nr+ii), ds.cid(ii), this_attr];
%     print_dlm_line(v, 'dlm', ',', 'fid', fid);
% end

% edge def
if ~isdirected
    [ir, ic] = find(triu(ds.mat,1));
    if isweighted
        ind = sub2ind(size(ds.mat), ir, ic);
        fprintf(fid, 'edgedef>node1 INT,node2 INT,weight DOUBLE\n');
        fprintf(fid, '%d,%d,%g\n', [ir, ic, ds.mat(ind)]');
    else
        fprintf(fid, 'edgedef>node1 INT,node2 INT\n');
        fprintf(fid, '%d,%d\n', [ir, ic]');
    end
else
    [ir, ic] = find(ds.mat - diag(diag(ds.mat)));
    if isweighted
        ind = sub2ind(size(ds.mat), ir, ic);
        fprintf(fid, 'edgedef>node1 INT,node2 INT,directed BOOLEAN,weight DOUBLE,label VARCHAR\n');
        fprintf(fid, '%d,%d,true,%g,%2.2f\n', [ir, ic, ds.mat(ind), ds.mat(ind)]');
    else
        fprintf(fid, 'edgedef>node1 INT,node2 INT,directed BOOLEAN\n');
        fprintf(fid, '%d,%d,true\n', [ir, ic]');
    end
end

fclose(fid);

end