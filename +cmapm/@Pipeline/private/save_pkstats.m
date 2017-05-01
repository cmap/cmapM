function save_pkstats(outfile, pkstats)
% SAVE_PKSTATS Save detected peak statistics.
%   SAVE_PKSTATS(OUTFILE, PKSTATS) Saves the statistics to OUTFILE in a
%   tab-delimited text file. PKSTATS is a structure returned by DPEAK.

error(nargchk(2,2, nargin))
if ~isstruct(pkstats)
    error ('PKSTATS must be a structure');
end

mktbl(outfile, pkstats, 'precision', 2);

end