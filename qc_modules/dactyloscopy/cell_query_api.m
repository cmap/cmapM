function out = cell_query_api(varargin)
% Function to query api.clue.io
% Example:
%   cell_query_api('--user_key','abc1234567890','--where','"cell_id":"PC3","gender":"M"')
%
% E-mail: Marek Orzechowski morzech@broadinstitute.org
%% ArgsParse
pnames = {'--api_url','--user_key','--where','--fields','--limit','--skip','--order'};

dflts = {'https://dev-api.clue.io','','', '', 1000, 0, 'ASC'};

config = struct('name',pnames, 'default',dflts,...
    'help',{'URL to the API (has to contain https://, e.g. https://api.clue.io)',...
    'User key to the API',...
    'Specifies a set of logical conditions to match, similar to a WHERE clause in a SQL query', ...
    'Specifies properties (fields) to include or exclude from the results.',...
    'Limits the number of records returned to the specified number (or less).', ...
    'Omits the specified number of returned records. This is useful, for example, to paginate responses.', ...
    'Specifies how to sort the results: ascending (ASC) or descending (DESC) based on the specified property.'});

opt = struct('prog', mfilename, 'desc',...
    'Run API query', 'undef_action','error');

args = mortar.common.ArgParse.getArgs(config, opt, varargin{:});
%disp(args)

%% URL suffix
url_suffix = '/api/cells?filter=';

%% A list of possible fields in the "--where" option
possible_fields = {'cell_histology','cell_id','cell_lineage',...
    'cell_source','cell_source_id','cell_type','gender',...
    'is_from_metastasis','lincs_status','metastatic_site',...
    'mutations','id','derived_cell_lines'}';

% The entire string in "--where" option is chopped into individual pieces to
% verify if all the fields are allowed.
if iscell(args.where)
    where_ini = strsplit(args.where{1},',');
else
    where_ini = strsplit(args.where,',');
end
where_cell = cell(1,2);
for ii = 1:length(where_ini)
    where_subcell = strsplit(where_ini{ii},':');
    where_cell(ii,1) = {strrep(where_subcell{1},'"','')};
    where_cell(ii,2) = {strrep(where_subcell{2},'"','')};
end

if sum(ismember(where_cell(:,1),possible_fields)) ~= length(where_cell(:,1))
    fprintf('%s> Some of the fields in the "--where" option are not recognized. Possible fields are:\n',...
        mfilename)
    disp(possible_fields)
    error('%s> Syntax in the "-where" option needs to be corrected. Exiting now.',...
        mfilename)
end

%% Assert that the user key is defined
if isempty(args.user_key)
    error('%s> User key to the API was not provided.', mfilename)
end

%% Construct a query string
if isempty(args.fields)
    query_str = strcat(args.api_url, url_suffix,...
        '{"where":{',args.where,'},',...
        '"limit":',num2str(args.limit),',',...
        '"skip":',num2str(args.skip),',',...
        '"order":"',args.order,'"}&',...
        'user_key=',args.user_key);
else
    query_str = strcat(args.api_url, url_suffix,...
        '{"where":{',args.where,'},',...
        '"fields":[',args.fields,'],',...
        '"limit":',num2str(args.limit),',',...
        '"skip":',num2str(args.skip),',',...
        '"order":"',args.order,'"}&',...
        'user_key=',args.user_key);
end
%disp(query_str{1})

%% Run a query
try
    out = webread(query_str);
catch ME
    fprintf('%s> API server issued a warning:\n%s\n',mfilename, ME.message);
    out = '';
end
end