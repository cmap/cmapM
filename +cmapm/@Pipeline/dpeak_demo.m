function [lxb, pkstats] = dpeak_demo
% DPEAK_DEMO Demo of peak detection.
% [LXB, PKSTATS] = DPEAK_DEMO Performs peak detection on data from a single
% well Generates histograms for a few analytes showing the detected peaks
% and returns raw data structure (LXB) and a stucture with statistics of
% the detected peaks for all analytes (PKSTATS)

lxbfile = fullfile(cmapmpath, 'test_data', 'A10.lxb');
sample_analytes = [15, 25, 100, 200, 300];
 
% plot peak intensity distributions for a few analytes
fprintf ('Plotting distributions...\n');
lxb = l1k_plot_peaks(lxbfile, sample_analytes);
drawnow

% detect peaks and return stats
fprintf('Detecting peaks...\n');
pkstats = detect_lxb_peaks_multi(lxb.RP1, lxb.RID, 'showfig', false);
fprintf('Done\n')

end