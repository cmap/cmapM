function ds_out = ds_concatenate_meta(ds,dim,fields,field_name,varargin)
%ds_out = ds_concatenate_meta(ds,dim,fields,field_name)
%
%Adds an annotation to a dataset with a concatenation of fields already in
%the dataset
%
%Input:
%       ds: dataset
%       dim: either 'row' or 'column'
%       fields: a cell array of the annotation fields to concatenate
%       field_name: name of the new concatenated field
%       delimiter: Delimiter to use for concatenation. Default '_'
%
%Output:
%       out_ds: the new annotated data set
%
%Example:
%
%ds_out = ds_concatenate_meta(ds, 'column', {'pert_id','cell_id'},'pert-cell','delimiter',':')

params = {'delimiter'};
dflts = {'_'};
args = parse_args(params,dflts,varargin{:});

switch lower(dim)
    case 'column'
        assert(all(ismember(fields,ds.chd)),'Some column fields not present in ds!');
        
        [idx,locb] = ismember(ds.chd,fields);
        
        %ensure that the order of the concatenation matches the input
        %That is, if fields = {'pert_id','cell_id'} the new concatenated
        %field should look like 'sirolimus_MCF7' instead of
        %'MCF7_sirolimus'
        locb(locb == 0) = [];
        desc = ds.cdesc(:,idx);
        desc = desc(:,locb);
        
        rows = mat2cell(desc,ones(size(desc,1),1),size(desc,2));
        rows2 = cellfun(@(x) strjoin(x,args.delimiter),rows,...
            'uni',0);
        
        annot = struct('id',ds.cid,...
            field_name,rows2);
        ds_out = annotate_ds(ds,annot,...
            'dim','column');
        
    case 'row'
        assert(all(ismember(fields,ds.rhd)),'Some row fields not present in ds!');
        
        [idx,locb] = ismember(ds.rhd,fields);
        
        %ensure that the order of the concatenation matches the input
        locb(locb == 0) = [];
        desc = ds.rdesc(:,idx);
        desc = desc(:,locb);
        
        rows = mat2cell(desc,ones(size(desc,1),1),size(desc,2));
        rows2 = cellfun(@(x) strjoin(x,args.delimiter),rows,...
            'uni',0);
        
        annot = struct('id',ds.rid,...
            field_name,rows2);
        ds_out = annotate_ds(ds,annot,...
            'dim','row');
    otherwise
        error('Invalid dimension. Must be either "row" or "column"')
        
end

end

