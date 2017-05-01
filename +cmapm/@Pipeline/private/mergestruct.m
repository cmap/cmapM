function sout = mergestruct(varargin)
% MERGESTRUCT Merge structures with unique fields.
% See: http://blogs.mathworks.com/loren/2009/10/15/concatenating-structs/

%   Copyright 2009 The MathWorks, Inc.
    
% Start with collecting fieldnames, checking implicitly
% that inputs are structures.
fn = [];
for k = 1:nargin
    try
        fn = [fn ; fieldnames(varargin{k})];
    catch MEstruct
        throw(MEstruct)
    end
end

% Make sure the field names are unique.
if length(fn) ~= length(unique(fn))
    error('mergestruct:FieldsNotUnique',...
        'Field names must be unique');
end

% Now concatenate the data from each struct.  Can't use
% structfun since input structs may not be scalar.
c = [];
for k = 1:nargin
    try
        c = [c ; struct2cell(varargin{k})];
    catch MEdata
        throw(MEdata);
    end
end

% Construct the output.
sout = cell2struct(c, fn, 1);
