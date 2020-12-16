function mk_luminex_csv(csv_file, hd_struct, median_ds, count_ds)
% MK_LUMINEX_CSV Create a Luminex compatible CSV file
% mk_luminex_csv(csv_file, hd_struct, median_ds, count_ds)

assert(isstruct(hd_struct),...
    'Expected Header to be a structure, got %s instead',...
    class(hd_struct))
median_ds = parse_gctx(median_ds);
count_ds = parse_gctx(count_ds);
%cmn_cid = intersect(median_ds.cid, count_ds.cid);
%cmn_rid = intersect(median_ds.rid, count_ds.rid);
%median_ds = ds_slice(median_ds, 'cid', cmn_cid, 'rid', cmn_rid);
%count_ds = ds_slice(count_ds, 'cid', cmn_cid, 'rid', cmn_rid);
[nanalyte, nsample] = size(median_ds.mat);
[nanalyte2, nsample2] = size(count_ds.mat);
assert(isequal(nanalyte, nanalyte2),...
    'Expected number of analytes to match for median and count data structures')
assert(isequal(nsample, nsample2),...
    'Expected number of samples to match for median and count data structures')
assert(isequal(median_ds.cid, count_ds.cid), 'cid mismatch');
assert(isequal(median_ds.rid, count_ds.rid), 'rid mismatch');

dbg(1, '# Creating Luminex CSV: %s', csv_file);
fid = fopen(csv_file, 'wt');

write_header(fid, hd_struct, nsample);
write_block(fid, 'Median', median_ds, 2);
write_block(fid, 'Count', count_ds, 0);

fclose(fid);
dbg(1, '# Done');

end

function write_header(fid, hd_struct, nsample)
hdrfields = {'Program';...
'Build';...
'Date';...
'SN';...
'Batch';...
'Version';...
'Operator';...
'ComputerName';...
'Country Code';...
'ProtocolName';...
'ProtocolVersion';...
'ProtocolDescription';...
'ProtocolDevelopingCompany';...
'SampleVolume';...
'DDGate';...
'SampleTimeout';...
'BatchStartTime';...
'BatchStopTime';...
'BatchDescription';...
'ProtocolPlate';...
'ProtocolMicrosphere';...
'ProtocolAnalysis';...
'NormBead';...
'ProtocolHeater'};

nfield = length(hdrfields);
dbg(1, '# Writing header');
for ii=1:nfield
    if isfield(hd_struct, hdrfields{ii})
        this_val = hd_struct.(hdrfields{ii});
    else
        this_val = '';
    end
    fprintf(fid, '"%s", "%s"\n', hdrfields{ii}, this_val);
end

fprintf(fid, '"Samples","%d","Min Events","500","Per Bead"\n', nsample);
fprintf(fid, '"Results"\n');
end


function write_block(fid, block_name, block_ds, num_precision)
dbg(1, '# Writing datablock: %s', block_name);
fprintf(fid, '"DataType:","%s"\n', block_name);
[nanalyte, nsample] = size(block_ds.mat);

analyte_label = gen_labels(nanalyte, 'prefix', 'Analyte ', 'zeropad', false);
col_labels = [{'Location'; 'Sample'}; analyte_label; 'Total Events'];
[wn, word] = get_wellinfo(block_ds.cid, 'zeropad', false);
row_vals = [num2cell(word), wn]';
row_desc = row_vals(1, :);

row_labels = tokenize(sprintf('"%d(1,%s)"#', row_vals{:}), '#');
row_desc_labels = tokenize(sprintf('Unknown%d#', row_desc{:}), '#');
row_labels = row_labels(1:end-1);
row_desc_labels = row_desc_labels(1:end-1);

print_dlm_line(col_labels, 'fid', fid, 'dlm', ',');
for ii=1:nsample
    this_row = [row_labels(ii); row_desc_labels(ii); num2cell(block_ds.mat(:, ii)); {0}];
    print_dlm_line(this_row, 'fid', fid, 'dlm', ',', 'precision', num_precision);
end
fprintf(fid, '\n');

end
