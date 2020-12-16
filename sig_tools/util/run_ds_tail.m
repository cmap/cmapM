function [status, result] = run_ds_tail(infile, outpath, score_type, tail_size)

cmd = sprintf('%s/ds_tail.sh -i %s -o %s -t %s -n %d',...
    fullfile(mortarpath, 'ext/bin'), infile, outpath,...
    score_type, tail_size);
dbg(1, cmd);
[status, result] = system(cmd);