function mkgctfast(ofile, ds, varargin)
% MKGCTFAST Create a gct file (experimental fast version)
%   MKGCTFAST(OFILE, GEX) Creates OFILE in gct format. GEX is a structure with
%   the following fields:
%   Creates a v1.3 GCT file named OFILE. GEX is a structure with the
%   following fields:
%       mat: Numeric data matrix [RxC]
%       rid: Cell array of row ids
%       rhd: Cell array of row annotation fieldnames
%       rdesc: Cell array of row annotations
%       cid: Cell array of column ids
%       chd: Cell array of column annotation fieldnames
%       cdesc: Cell array of column annotations
%       version: GCT version string
%       src: Source filename

% TODO: implement mkgct options that are largely ignored for now
pnames = {'--precision', '--appenddim', '--version', ...
    '--parsetags', '--annot_precision', '--checkid'};
dflts = {inf, true, 3,...
    true, inf, true};

config = struct('name', pnames,...
    'default', dflts);
opt = struct('prog', mfilename, 'desc', ' Create a gct file (experimental fast version)');
[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});
[nr, nc] = size(ds.mat);
cid = ds.cid;
nchd = length(ds.chd);
nrhd = length(ds.rhd);
dims = [nr, nc, nrhd, nchd]; 
rhd = ds.rhd;
[p, f, ~] = fileparts(ofile);
if args.appenddim    
    % strip old dimension if it exists
    prefix = rm_filedim(f);
    ofile = fullfile(p, sprintf('%s_n%dx%d.gct', prefix, nc, nr));
else
    ofile = fullfile(p, [f, '.gct']);
end

% cast to table since its faster to write
[ds, col_meta] = gct2tbl(ds, 'as_table', true, 'id_name', 'id');
if ~isinf(args.precision)
    for ii=1:length(cid)
        ds.(cid{ii}) = num2cellstr(ds.(cid{ii}), 'precision', args.precision);
    end
end

has_col_meta = length(fieldnames(col_meta)) > 1;
dbg(1, 'Writing dataset [%dx%d] to %s', nr, nc, ofile);
writetable(ds, ofile, 'FileType', 'text',...
           'Delimiter', '\t',...
           'QuoteStrings', false,...
           'WriteVariableNames', ~has_col_meta);

% prepend GCT header using system sed
insert_gct_header(ofile, args.version, dims, col_meta, rhd)

end

function insert_gct_header(ofile, version, dims, col_meta, rhd)

switch(version)
    case 3
        has_col_meta = length(fieldnames(col_meta)) > 1;
        if has_col_meta
            [~, lines] = get_cmeta_table(col_meta, rhd);
        else
            lines = {};
        end
        [sed_cmd, is_gnu_sed] = get_sed_cmd;
        [sed_pat, line_str] = get_sed_pattern(version, dims, lines);
        if ~isempty(sed_cmd)
            dbg(1, 'Inserting GCT header using %s', sed_cmd);
            if is_gnu_sed
                shell_cmd = sprintf('%s -i ''%s'' %s', sed_cmd, sed_pat, ofile);
            else
                shell_cmd = sprintf('%s -i "" ''%s'' %s', sed_cmd, sed_pat, ofile);
            end
            [status,result] = system(shell_cmd);
            if ~isequal(status, 0)
                dbg(1, 'Insert header failed with status %d: result:%s', status, result);
                disp(shell_cmd);
                p = fileparts(ofile);
                err_file = fullfile(p, 'sed_cmd.txt');
                dbg(1, 'Saving sed command to %s', err_file);
                mortar.util.Message.log(err_file, shell_cmd);
            end            
        else 
            p = fileparts(ofile);
            header_file = fullfile(p, 'gct_header.txt');
            warning('No system sed found writing the GCT header to append manually if needed %s', header_file);
            fid = fopen(header_file, 'wt');
            fprintf(fid, '%s', strrep(line_str, '\', ''));
            fclose(fid);            
        end                        

    otherwise
        error('Unsupported version %d', version)
end

end

function [tbl, lines] = get_cmeta_table(cm, rhd)

cid = {cm.cid}';
chd = setdiff(fieldnames(cm), {'cid'}, 'stable');
nrhd = length(rhd);
ncid = length(cid);
tbl = cell(length(fieldnames(cm)), 1+length(rhd)+length(cid));
tbl(1, :) = [{'id'}; rhd; cid];
tbl(2:end, 1) = chd;
tbl(2:end, (1:nrhd)+1) = {'na'};
cm_cell = struct2cell(rmfield(cm, 'cid'));
%cm_cell = cellfun(@stringify, cm_cell, 'UniformOutput', false);
tbl(2:end, (1:ncid) + nrhd + 1) = cm_cell;
lines = cell(size(tbl, 1), 1);
for ii = 1:length(lines)
    this_line = print_dlm_line(tbl(ii, :), 'dlm', '\\\t');
    this_line = strrep(this_line, '/','\/');
    lines{ii} = sprintf('%s', this_line);
end

end


function [sed_pat, s] = get_sed_pattern(version, dims, lines)
switch(version)
    case 3
        s = sprintf('#1.3\\\n%d\\\t%d\\\t%d\\\t%d\\\n', dims);
        if ~isempty(lines)
            s = sprintf('%s%s', s, sprintf('%s\\\n',lines{:}));
        end
        sed_pat = sprintf('1s/^/%s/', s);
    otherwise
        error('Unsupported version %d', version);
end

end
