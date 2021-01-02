function [bench_ds, system_rpt] = run_matlab_bench(niter)
% RUN_MATLAB_BENCH Report matlab benchmarks 
%   [BENCH_DS, SYS_RPT] = RUN_MATLAB_BENCH(N)
% Runs matlab BENCH N times and returns the times in BENCH_DS. SYS_RPT
% contains system information

if ~nargin
    niter=1;
end

timestamp = datestr(now);
matlab_version = version;
host = hostname;

system_rpt = struct('hostname', host,...
                    'matlab_version', matlab_version,...
                    'timestamp', timestamp);

cid = {'lu'; 'fft'; 'ode'; 'sparse'; 'plot_2d'; 'plot_3d'};                
t = bench(niter);
rid = gen_labels(niter, 'prefix', 'iter_', 'zeropad', false);
bench_ds = mkgctstruct(t, 'cid', cid, 'rid', rid);

               
end