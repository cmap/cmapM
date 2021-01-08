function ofname = mk_html_table(outfile, tbl, varargin)
% MK_HTML_TABLE Generate a HTML page with a table and links.
%   MK_HTML_TABLE(OUTFILE, TBL) Constructs a table from a structure array
%   TBL such that the column names correspond to the fieldnames and the
%   rows correspond to the entries in each element in the structure array.
%
%   MK_HTML_TABLE(OUTFILE, TBL, 'figures', FIG) Adds links to figures
%   listed in the structure FIG. One field in FIG should correspond to that
%   in TBL

opt = struct('name', {'--table_name', '--sort_field', '--sort_order',...
                      '--hide_column', '--figures', '--figure_field',...
                      '--title', '--link_type', '--float_precision'},...
             'default', {'dynamic_table', '', 'asc',...
                        '', '', '',...
                        'Data Grid', 'image', 3});
p = mortar.common.ArgParse(mfilename);
p.add(opt);
args = p.parse(varargin{:});

if ischar(tbl)
    tbl = parse_tbl(tbl, 'outfmt', 'record');
end

% build dict for table
[tableMap, fieldList] = format_table(tbl, args);

% dict of figures
if ~isempty(args.figures)
    if ischar(args.figures)
        args.figures = parse_tbl(args.figures, 'outfmt', 'record');
    end
    fig_fields = fieldnames(args.figures);
    [key_field, link_column] = intersect(fieldList, fig_fields);
    assert(isequal(length(key_field), 1), 'One unique key field expected');
    val_field = setdiff(fig_fields, key_field);
    p = path_relative_to(fileparts(outfile), {args.figures.(val_field{1})}');    
    figureMap = hashmap({args.figures.(key_field{1})}', p);
elseif isfield(tbl, 'url')
    p = path_relative_to(fileparts(outfile), {tbl.url}');
    figureMap = hashmap({tbl.(fieldList{1})}', p);
    tbl = rmfield(tbl, 'url');
    [tableMap, fieldList] = format_table(tbl, args);    
    link_column = 1;
else
    figureMap = hashmap();
    link_column = 1;
end

template_path = fullfile(mortarpath, 'templates');
% template =  'html_table_dev.vm';
template =  'html_table.vm';

% zero-indexed column index to sort on
if ~isempty(args.sort_field)
    assert(any(isfield(tbl, args.sort_field)), 'Sort field not found');
    sort_field = args.sort_field;
else
    sort_field = '';
end

% one indexed to account for the index column
sort_column = find(strcmp(sort_field, fieldList));
if isempty(sort_column)
    sort_column = 0;
end

if ~isempty(args.hide_column)
    hide_column = print_dlm_line(find(ismember(fieldList, args.hide_column)), 'dlm', ',');
else
    hide_column = '';
end

opt = hashmap({'title', 'sort_column', 'sort_order',...
               'hide_column', 'link_column'}, ...
               {args.title, int32(sort_column), args.sort_order,...
               hide_column, int32(link_column)});

%%
add_velocity_jar;

% Initialize Velocity
ve = org.apache.velocity.app.VelocityEngine();
ve.setProperty('file.resource.loader.path', template_path);
ve.setProperty('velocimacro.library', 'global_macros.vm');
ve.init()
tpl = ve.getTemplate(template);

% Create a context and add data 
context = org.apache.velocity.VelocityContext();
context.put('tableMap', tableMap);
context.put('fieldList', fieldList);
context.put('figureMap', figureMap);
context.put('opt', opt);
% write to file
fileWriter = java.io.OutputStreamWriter(...
    java.io.FileOutputStream(outfile));
tpl.merge(context, fileWriter);
fileWriter.close();

end

function [tableMap, fieldList] = format_table(tbl, args)

fieldList = fieldnames(tbl);
isonerow = isequal(length(tbl), 1);
tblcell = struct2cell(tbl)';
tableMap = linkedhashmap;
nfn = length(fieldList);
for ii=1:nfn
    x = [tblcell{:, ii}]';
    isnum = isnumeric_type(x);
    if isnum    
        % set precision of floats
        tmp = num2cell(roundn(x, -args.float_precision));
        [tblcell{:, ii}] = tmp{:};
    else
        
    end
end
if isonerow
    tableMap.put(args.table_name, {tblcell});
else
    tableMap.put(args.table_name, tblcell);
end
end
