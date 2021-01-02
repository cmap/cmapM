function [pkstats,fn] = dpeakFolder(lxb_path, varargin)

detect_params = mortar.prism.dpeak.detect_params;
default_args = args2cell(detect_params);

[pkstats,fn] = detect_lxb_peaks_folder(lxb_path, default_args{:}, varargin{:});


end