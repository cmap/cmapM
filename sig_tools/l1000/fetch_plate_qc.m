function [] = fetch_plate_qc(infile,outfile)
% fetch_failed_qc takes a .txt or .grp file that is a list of plates that
% failed entmoot and combines aggregates a file that contains summary qc
% plots for the failed plates.

fid = fopen(infile);
failed_plates = textscan(fid,'%s');
failed_plates = sort(failed_plates{1});
fclose(fid);
tmp = repmat(failed_plates,4,1);
groups = sort(tmp);

plots = repmat({'calibplot.png';'quantiles_raw.png';'plate_count.png';'beadset_ctrl.png'},length(failed_plates),1);
caption = repmat({'calibplot' ;'quantiles_raw'; 'plate_count';'beadset_ctrl'},length(failed_plates),1);
qcfiles = strcat('/cmap/data/roast/core/',groups(:), '/qc/figures/', plots(:));

title = ['Entmoot Failed Plates: ' datestr(now,'mmmm dd, yyyy HH:MM AM')];
mkpdf(outfile, qcfiles,'title',title,'caption',caption,'group',groups);
end