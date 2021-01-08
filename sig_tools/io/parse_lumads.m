% PARSE_LUMADS Wrapper function for parsing Luminex gct or csv files

function ds = parse_lumads(fn, varargin)

%if struct, pass through
if isstruct(fn)
    ds = fn;
else
    fn = parse_filename(fn, 'wc', '*.csv,*.gct');
    for ii=1:length(fn)
        [p,f,e] = fileparts(fn{ii});
        switch lower(e)
            case '.gct'
                ds(ii) = parse_gct0(fn{ii}, varargin{:});
            case '.csv'
                ds(ii) = parse_csv0(fn{ii}, varargin{:});
            otherwise
                error (mfilename, '%s Unknown format', e)
        end
    end
end