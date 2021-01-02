% ISHTA check if filename is an affymetrix High-throughput array (HTA).
%   RES = ISHTA(CEL_FILENAME) returns true if CEL_FILENAME is a c-map HTA
%   and false otherwise. CEL_FILENAME can be a character array or a cell
%   array of strings.

function yn = ishta(celfilename)

if iscell(celfilename)
    yn = cellfun(@(x) isempty(x), regexpi(celfilename, '^[EC]')) & ...
        cellfun(@(x) ~isempty(x), regexpi(celfilename, '^[0-9]'));
else
    yn = isempty(regexpi(celfilename, '^[EC]')) & ~isempty(regexpi(celfilename, '^[0-9]'));
end

