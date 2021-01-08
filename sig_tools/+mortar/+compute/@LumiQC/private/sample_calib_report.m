% generate a sample-level summary report of the calib parameters
function report = sample_calib_report(calibds, ds, varargin)

pnames = {'fmt', 'tokenize_desc'};
dflts =  {'%6.2f', false};
arg = parse_args(pnames, dflts, varargin{:});
nPlate = length(calibds);

%SAMPLE_NAME, DESC, CCSCORE, MED_INT, GAPDH, G01-XX, DYN_RANGE_RATIO, SPAN

[nLevel,nSample] = size(calibds.mat);
%report.PLATE(:,1) = gen_labels(ones(nSample,1)*ii);
report.SAMPLE_NAME(:,1) = ds.cid;

if any(strcmp('cdesc', fieldnames(ds)))
    switch class(calibds.cdesc)
        case 'cell'
         for ii = 1:length(ds.chd)
             report.(upper(ds.chd{ii})) = ds.cdesc(:,ii);
         end
        case 'containers.Map'
            if ~isempty(ds.cdesc)
                if arg.tokenize_desc
                    keys = ds.cdesc.keys;
                    for ii=1:length(keys)
                        report.(upper(keys{ii})) = ds.cdesc(keys{ii});
                    end
                else
                    report.DESC = dict2tags(ds.cdesc);
                end
            end
        otherwise
            warning('Sample desc has unsupported class, skipping...')
    end
end
% sample score
report.CCSCORE(:,1) = num2cellstr(compute_cc_score(calibds));

%dynamic range
report.DYN_RANGE(:,1) = num2cellstr(calibds.mat(end,:) ./ calibds.mat(1,:));
report.DYN_RANGE_MAX(:,1) = num2cellstr(max(calibds.mat) ./ calibds.mat(1,:));
%span
report.SPAN(:,1) = num2cellstr(max(calibds.mat) - calibds.mat(1,:));

%median intensity
report.MED_INT(:,1) = num2cellstr(nanmedian(ds.mat, 1),'-fmt',arg.fmt)';

%GAPDH
[cmn, gidx] = intersect(ds.rid, {'GAPD_3_CTRL','GAPDH','0_dp:null:GAPDH:LUA-95',...
    '4463_dp:217398_x_at:GAPDH:LUA-95:Analyte_463:cdp1','4501_dp:217398_x_at:GAPDH:LUA-95:Analyte_1:dp2',...
    '4502_dp:217398_x_at:GAPDH:LUA-95:Analyte_1:dp3','IIE8F8','217398_x_at'});

if ~isempty(gidx)
    report.MED_GAPDH(:,1) = num2cellstr(ds.mat(gidx(1), :),'-fmt',arg.fmt)';
else
    report.MED_GAPDH(1:nSample,1) = {'NA'};
end

level_lbl = gen_labels(nLevel, '-prefix', 'INV_LEVEL_');
for jj=1:nLevel
    report.(level_lbl{jj})(:,1) = num2cellstr(calibds.mat(jj,:)','-fmt',arg.fmt);
end

end


