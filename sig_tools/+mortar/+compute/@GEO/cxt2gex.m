function [gex, missing] = cxt2gex(cxtlist, varargin)
% CXT2GEX Create a gct structure from CXT files
%   GEX = CXT2GEX(CXTLIST)
%   GEX = CXT2GEX(CXTLIST, name, value)
%   'cxt_path': Path to CXT files. 
%   'rid': Feature space to include. 

pname = {'cxt_path',...
    'rid',...
    'verbose'};
dflts = {fullfile(mortarconfig('bged_path'), 'cxt'),...
    fullfile(mortarconfig('vdb_path'), 'spaces/affx_n22268.grp'),...
    true};
args = parse_args(pname, dflts, varargin{:});

start_time = tic;
fprintf('-[ %s ]- Start\n', upper(mfilename));

cxt={};
if iscell(cxtlist) || isfileexist(cxtlist)
    cxt = parse_grp(cxtlist);
end

if iscell(args.rid) || isfileexist(args.rid)
    args.rid = parse_grp(args.rid);
end
ncxt = length(cxt);
cxtexists = true(ncxt, 1);
if ~isempty(cxt)
    [cxtname, cxtlbl] = get_cxtname(args.cxt_path, cxt);
    %     ds = parse_cxt(cxtname{1});
    % alert = max(1, round(ncxt/10));
    
    for ii=1:ncxt
        if isfileexist(cxtname{ii});
            dbg(args.verbose, 'Parsing %s', cxtname{ii});
            ds = parse_cxt_fast(cxtname{ii});
            if isequal(ii,1)
                if ~isempty(args.rid)
                    rmap = list2dict(args.rid);
                    rid = intersect_ord(ds.rid, args.rid);
                else
                    rmap = list2dict(ds.rid);
                    rid = ds.rid;
                end
                nrid = length(rid);
                gex = mkgctstruct(zeros(nrid, ncxt),...
                    'rid', rid,...
                    'cid', cxtlbl,...
                    'chd', {'array','num_features','pcall_percent'});
            end
            
            ridx = rmap.isKey(ds.rid);
            if ~isequal(nrid, nnz(ridx))
                disp(setdiff(rid, ds.rid(ridx)))
                error('Some features not found: %s', cxtname{ii})
            end
            mapidx = cell2mat(rmap.values(ds.rid(ridx)));
            gex.mat(mapidx, ii) = ds.mat(ridx, :);
            gex.cdesc(ii, gex.cdict('pcall_percent')) = ...
                num2cellstr(100 * nnz(strcmp('P', ds.rdesc(ridx, ds.rdict('pcalls')))) ./ nrid, 'precision', 0);
            gex.cdesc(ii, gex.cdict('array')) = ds.cdesc(ds.cdict('array'));
            gex.cdesc(ii, gex.cdict('num_features')) = ds.cdesc(ds.cdict('num_features'));
        else
            dbg(args.verbose, 'File not found %s', cxtname{ii});
            cxtexists(ii) = false;
        end
    end
    
    % skip missing
    gex = ds_slice(gex, 'cid', gex.cid(cxtexists));
    missing = cxtlbl(~cxtexists);
    
    % get qc stats from 22k space
    qcstats = get_qc(gex);
    % append stats
    gex = annotate_ds(gex, qcstats, 'dim', 'column');
    
    fprintf('-[ %s ]- Stop. (%2.2fs)\n', upper(mfilename), toc(start_time));
end

end

function qc = get_qc(ds)
% compute QC stats
qc = struct('id', ds.cid,...
    'mean_int','',...
    'std_int','',...
    'gap35_ratio', '',...
    'act35_ratio', '',...
    'spike_int', '',...
    'is_spike_ascend', '');

% mean
mean_int = num2cellstr(mean(ds.mat),'precision', 1);
[qc.mean_int] = mean_int{:};

% std
std_int = num2cellstr(std(ds.mat), 'precision', 1);
[qc.std_int] = std_int{:};

% GAPDH and beta-actin levels
gap35_ratio = num2cellstr(ds.mat(strcmp('AFFX-HUMGAPDH/M33197_3_at', ds.rid),:) ./ ...
    ds.mat(strcmp('AFFX-HUMGAPDH/M33197_5_at', ds.rid), :), 'precision', 2);
[qc.gap35_ratio] = gap35_ratio{:};

act35_ratio = num2cellstr(ds.mat(strcmp('AFFX-HSAC07/X00351_3_at', ds.rid),:) ./ ...
    ds.mat(strcmp('AFFX-HSAC07/X00351_5_at', ds.rid), :), 'precision', 2);
[qc.act35_ratio] = act35_ratio{:};

% Intensities of BioB, BioC, BioD, CreX
[~, spikeIdx] = intersect_ord(ds.rid, ...
    {'AFFX-r2-Ec-bioB-3_at', 'AFFX-r2-Ec-bioC-3_at', 'AFFX-r2-Ec-bioD-3_at', 'AFFX-r2-P1-cre-3_at'});
if length(spikeIdx) ~= 4
    [~,  spikeIdx] = intersect_ord(ds.rid, ...
        {'AFFX-BioB-3_at', 'AFFX-BioC-3_at', 'AFFX-BioDn-3_at', 'AFFX-CreX-3_at'});
end
nc = length(ds.cid);
spike_int = cell(nc,1);
is_spike_ascend = cell(nc,1);

for ii=1:nc
    spike_int{ii} = print_dlm_line2(ds.mat(spikeIdx, ii), 'dlm', '|', 'precision', 0);
    % Are Intensities of spike controls in ascending order  BioB<BioC<BioD<CreX
    if all(diff(ds.mat(spikeIdx, ii))>0)
        is_spike_ascend{ii} = 'Y';
    else
        is_spike_ascend{ii} = 'N';
    end
    %     % pcall pct
    %     pcall_percent{ii} = num2cellstr(100*nnz(strcmp('P', ds.pcalls))/length(ds.rid), 'precision', 2);
end
[qc.spike_int] = spike_int{:};
[qc.is_spike_ascend] = is_spike_ascend{:};
% qc.pcall_percent = pcall_percent;

end

function [cxtname, cxtlbl] = get_cxtname(cxt_path, cxt)
cxtlbl = regexprep(cxt, '\.CXT\.gz$|\.gz$|\.CEL\.gz$|\.CEL$','');
cxt = strcat(cxtlbl, '.CXT.gz');
ncxt = length(cxt);
cxtname = cell(ncxt, 1);
for ii=1:ncxt
    cxtname{ii} = fullfile(cxt_path, cxt{ii});
end
end
