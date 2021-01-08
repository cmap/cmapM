function [tbl, col_meta] = gct2tbl(gct, varargin)
% GCT2TBL Convert GCT structure to table structure.
%   TBL = GCT2TBL(GCT)
%   [TBL, COL_META] = GCT2TBL(GCT) column meta data is not part of the main 
% table and returned separately

config = struct('name', {'--as_table', '--id_name'},...
    'default', {false, 'rid'});
opt = struct('prog', mfilename, 'desc', 'Save results produced by runCmapQuery');
[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

gct = parse_gctx(gct);
% column meta-data
col_meta = gctmeta(gct);

if ~isempty(gct.rhd)
    %fn = deduplicate_str(validvar([{args.id_name};gct.rhd;gct.cid], '_'));
    fn = deduplicate_str([{args.id_name};gct.rhd;gct.cid]);
    if args.as_table
        tbl = cell2table([gct.rid, gct.rdesc, num2cell(gct.mat)],...
            'variablenames', fn);
    else
        tbl = cell2struct([gct.rid, gct.rdesc, num2cell(gct.mat)],...
            fn, 2);
    end
else
    %fn = deduplicate_str(validvar([{args.id_name}; gct.cid], '_'));
    fn = deduplicate_str([{args.id_name}; gct.cid]);
    if args.as_table
        tbl = cell2table([gct.rid, num2cell(gct.mat)],...
            'variablenames', fn);
    else
        tbl = cell2struct([gct.rid, num2cell(gct.mat)],...
            fn, 2);
    end
end

end