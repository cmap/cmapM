function beadset_fingerprint(csv_file, map_file, out_path, count_thresh)
% BEAD_FINGERPRINT(CSV_FILE, MAP_FILE, OUT_PATH, COUNT_THRESH)

showfig = false;
map = parse_tbl(map_file);

[p, plate_name, e] = fileparts(csv_file);
tok = tokenize(plate_name,  '_');
plate_id = tok{4};

count_ds = parse_csv(csv_file, 'type', 'count');

% keep map for current plate_id
keep = strcmp(map.plate_id, plate_id);

% well names
wn = get_wellinfo(count_ds.cid);

% mapping wn to analyte id
well2analyte = mortar.containers.Dict(map.well_id(keep), map.analyte_id(keep));

all_analyte=str2double(strrep(count_ds.rid, 'Analyte ', ''));
% keep wells with mapped analytes
keep_well = find(well2analyte.iskey(wn));
wn = wn(keep_well);
count_ds = ds_slice(count_ds, 'cid', count_ds.cid(keep_well));

analyte = well2analyte(wn);

[c, ridx] = map_ord(all_analyte, analyte);
cidx = 1:length(analyte);
ind = sub2ind(size(count_ds.mat), ridx(:), cidx(:));

% counts for each mapped well
target_count = count_ds.mat(ind);
[max_count, max_ridx] = max(count_ds.mat, [], 1);
max_analyte = all_analyte(max_ridx);

isok = abs(analyte-max_analyte)<eps;

rpt = struct('plate_name', plate_name, 'plate_id', plate_id,...
            'well_id', wn, 'target_analyte', num2cell(analyte),...
            'target_count', num2cell(target_count),...
            'max_analyte', num2cell(max_analyte),...
            'max_count', num2cell(max_count(:)),...
            'isok', num2cell(isok));

% low counts
is_low_count = target_count<count_thresh;
low_rpt = rpt(is_low_count);
any_low_count = any(is_low_count);

%% Add plot of counts by well
% myfigure(showfig)
% plot(target_count, 'k', 'linewidth', 2);
% 
% if any_low_count
%     low_idx = find(is_low_count);
%     ylabelrt(texify(plate_name),'color', 'b', 'fontsize', 8);
%     hold on
%     plot(low_idx, target_count(low_idx), 'ro', 'markerfacecolor', 'r');
%     th = text(low_idx+0.5, double(target_count(low_idx)), wn(low_idx));
%     set(th, 'color', 'b', 'fontsize', 8);
%     ylabel('Bead count');
%     xlabel('Analyte');
%     title(sprintf('n=%d', length(analyte)));
%     plot_constant(count_thresh, true, 'color', 'r', 'linestyle', '--')       
%     namefig(sprintf('plotcount_%s', plate_name));
% end

%% Platemap with target counts

plot_platemap(target_count, wn, 'plateformat', '96',...
              'flagwell', wn(is_low_count),...
              'name', sprintf('targetcount_%s', plate_name),...
              'ylabelrt', plate_name, 'showfig', false,...
              'title', sprintf('Target count (n=%d)', length(analyte)),...
              'caxis', [0 30]);

% create folders if needed
out_total_count = fullfile(out_path, 'total_count');
out_low_count = fullfile(out_path, 'low_count');
out_heatmap = fullfile(out_path, 'heatmap');

if ~isdirexist(out_path)
    mkdir(out_path)
end
if ~isdirexist(out_total_count)
    mkdir(out_total_count)
end
if ~isdirexist(out_low_count)
    mkdir(out_low_count)
end
if ~isdirexist(out_heatmap)
    mkdir(out_heatmap)
end

mktbl(fullfile(out_total_count, sprintf('count_%s.txt', plate_name)), rpt);
if any_low_count
    mktbl(fullfile(out_low_count, sprintf('lowcount_%s.txt', plate_name)), low_rpt);
end
savefigures('out', out_heatmap, 'mkdir', false, 'overwrite', true, 'closefig', true);

end
