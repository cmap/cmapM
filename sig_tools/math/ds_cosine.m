function cc = ds_cosine(ds, varargin)
% DS_COSINE Compute pairwise cosine similarities for a dataset.
%   CC = DS_COSINE(DS) Compute cosine similarities between columns of the
%   dataset DS. A Wrapper function to cosine_similarity that returns a
%   dataset instead of a matrix.
%
%   CC = DS_COSINE(DS1, DS2) Compute cosine similarities between columns of the
%   dataset DS1 and DS2.
%
% See also COSINE_SIMILARITY

% compute similarities within one dataset
if (nargin < 2) || (~isfileexist(varargin{1}) && ~isstruct(varargin{1}))
    corrXX = true;
    if isfileexist(ds)
        ds = parse_gctx(ds);
    end
    
% Both x and y given, compute the pairwise similarities
else
    ds2 = varargin{1};
    if isfileexist(ds2)
        ds2 = parse_gctx(ds2);
        % subset and order rows identically
        ds2 = ds_slice(ds2, 'rid', ds.rid);
    end    
    varargin = varargin(2:end);
    corrXX = false;
end

%% Compute correlations
if corrXX
    cc = cosine_similarity(ds.mat);    
    cc = mkgctstruct(cc, 'cid', ds.cid, 'cdesc',ds.cdesc, 'chd', ds.chd,...
        'rid', ds.cid, 'rdesc', ds.cdesc, 'rhd', ds.chd);
else
    cc = cosine_similarity(ds.mat, ds2.mat);    
    cc = mkgctstruct(cc, 'cid', ds2.cid, 'cdesc',ds2.cdesc, 'chd', ds2.chd,...
        'rid', ds.cid, 'rdesc', ds.cdesc, 'rhd', ds.chd);    
end

end