% annot2struct converts .xlsx annotation file to struct 
% s = annot2struct(file,varargin)
% Arguments:
%   file - 'path/to/annot.xlsx'
%   'dim' - string, corresponding dimension of annotation, default is row
function s = annot2struct(file,varargin)

pnames = {'dim'};
dflts = {'row'};
args = parse_args(pnames,dflts,varargin{:});

if ~ismember(lower(args.dim),{'row','column'})
    error('Invalid dimension: %s',args.dim);
end

if iscellstr(file)
    if length(file)==1
        file=file{:};
    else
        error('Only one file input allowed: %d files input',length(file));
    end
end

if ~isfileexist(file,'file')
    error('File does not exist: %s',file);
end

disp('Reading:...');

[~,~,tbl]=xlsread(file);

if isempty(tbl)
   error('Empty table, check file: %s',file);
end

if strcmpi(args.dim,'column')
    tbl(1,1)={'well'};
end

%remove non-standard characters (non-alphanumeric/underscores)
varnames = regexprep(tbl(1,:),'\W','');

varnames = lower(matlab.lang.makeValidName(varnames));

s = cell2struct(tbl(2:end,:),varnames,2);

% add well positions to column annotations
if strcmpi(args.dim,'column')
    row = regexp([s.well],'[A-Z]{1}','match');
    col = regexp(s.well,'[0-9]{2}','match');
    [s.row] = row{:};
    [s.column] = col{:};
end

disp('[Done.]');