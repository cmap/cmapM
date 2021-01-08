function ds = assignPeaks(pkstats, varargin)

dpeak_opt = mortar.prism.dpeak.detect_params;
default_opt = args2cell(struct('min_peak_support', dpeak_opt.min_peak_support,...
                     'min_peak_support_pct', dpeak_opt.min_peak_support_pct ...
                     ));
            
ds = assign_lxb_peaks(pkstats, default_opt{:}, varargin{:});

end