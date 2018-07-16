% Note. This script relies on the cmapM package.
% '/path/with/gctx/files/to/test/*gct*' refers to a directory of GCT and/or GCTX files to time parsing operations on.
% 'out_directory' refers to a user-specified out directory to which timing results are written.
% Cache was cleared in between consecutive operations.

dir_info = dir('/path/with/gctx/files/to/test/*gct*');
file_paths = {dir_info.name};

file_names = cell(length(file_paths),1);
parse_times = zeros(length(file_paths), 1);
write_times = zeros(length(file_paths), 1);

for f=1:length(file_paths)
   try
      curr_path = [dir_info(1).folder,'/', file_paths{f}]
      parse_start = cputime;
      in_gctoo = cmapm.Pipeline.parse_gctx(curr_path)
      elapsed_parse_time = cputime - parse_start
   
      [path, name, ext] = fileparts(curr_path);
      if strcmp('.gct', ext)
          write_start = cputime;
           cmapm.Pipeline.mkgct(['out_directory/',name], in_gctoo)
          write_elapsed = cputime - write_start
      elseif strcmp(ext,'.gctx')
          write_start = cputime;
           cmapm.Pipeline.mkgctx(['out_directory/', name], in_gctoo)
          write_elapsed = cputime - write_start 
      end

      file_names{f} = [name,ext];
      parse_times(f) = elapsed_parse_time;
      write_times(f) = write_elapsed;
   catch
      disp([dir_info(1).folder,'/', file_paths{f}])
   end
end

T = table(parse_times, write_times, file_names);
writetable(T, 'matlab_timing_results.txt', 'Delimiter', '\t', 'WriteRowNames', true)
