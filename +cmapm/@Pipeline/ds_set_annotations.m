function ds = ds_set_annotations(ds, annot, varargin)
% DS_SET_ANNOTATIONS Annotate rows or columns in a dataset.
%   NEWDS = DS_SET_ANNOTATIONS(DS, ANNOT) Updates column annotations
%   in DS using the annotations table ANNOT.
%
%   NEWDS = DS_SET_ANNOTATIONS(DS, ANNOT, PARAM1, VAL1, ...) Specify optional
%   parameters:
%   'append' Appends to existing annotations if true. [{true}, false]
%   'dim'   Dimension to append to ['row', {'column'}]
%   'keyfield'  ANNOT field used to match to row or column of DS. Must be unique.
%               Default is 'id'
%   'skipmissing' Skip missing ids if true.  [true, {false}]
%   'missingval'    Value for missing ids if skipmissing is true.
%                   Default is '-666'

ds = annotate_ds(ds, annot, varargin{:});

end