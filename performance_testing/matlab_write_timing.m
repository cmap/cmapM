% Note. This script relies on the cmapM package.
% '/path/to/large/gctx/file' refers to a large GCTX file (any size above 10174x100000 should work) from which file subsets are made.
% In testing, the large GCTX file used lacked metadata; including metadata would cause slight variation in results.
% Cache was cleared in between consecutive operations.

big = cmapm.Pipeline.parse_gctx('/path/to/large/gctx/file');

rids = big.rid;
cids = big.cid;

file_names = cell(27, 1);
write_times = cell(27, 1);

col_spaces = [96 384 1536 3000 6000 12000 24000 48000 100000]
row_spaces = [978 10174]

for i=1:length(col_spaces)
	for j=1:length(row_spaces)
		col_slice = int([1:i]);
		row_slice = int([1:j]);

		curr_gct = cmapm.Pipeline.ds_slice(big, 'ridx', row_slice, 'cidx', col_slice);

		t = cputime;
		out_name = strcat(int2str(i), strcat('x', int2str(j)));
		disp(out_name);
		cmapm.Pipeline.mkgct(out_name, curr_gct)
		e = cputime - t;
		disp(e);

		file_names{i} = out_name;
		write_times{i} = e;
	end
end

T1 = cell2table(names,'VariableNames',{'file_names'});
T2 = cell2table(times, 'VariableNames', {'write_times'});

writetable(T1,'matlab_gct_writing_filenames.txt')
writetable(T2, 'matlab_gct_writing_filetimes.txt')