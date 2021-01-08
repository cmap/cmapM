function ds = assign_lxb_peaks(pkstats, varargin)
% ASSIGN_LXB_PEAKS: Assign detected peaks to genes.

pnames = {'ntag','min_support', 'min_support_pct', 'out'};
dflts = {2, 30, 20, '.'};
arg = parse_args(pnames, dflts, varargin{:});
%save parameters
% fid = fopen(fullfile(arg.out, sprintf('%s_params.txt', mfilename)), 'wt');
% print_args(mfilename, fid, arg)
% fclose(fid);
%
[nanalyte, nsample] = size(pkstats);
ds = struct('mat', zeros(nanalyte, nsample),...
    'label', gen_labels(arg.ntag, 'prefix', 'TAG:'),...
    'support', zeros(nanalyte,nsample),...
    'support_pct', zeros(nanalyte,nsample));

for jj=1:nsample
    for ii=1:nanalyte
        switch pkstats(ii,jj).method
            case {'median','missing'}
                for p=1:arg.ntag
                    ds(p).mat(ii, jj) = pkstats(ii,jj).pkexp;
                    ds(p).support(ii, jj) = pkstats(ii,jj).pksupport;
                    ds(p).support_pct(ii, jj) = pkstats(ii,jj).pksupport_pct;
                end
            otherwise
                npks = length(pkstats(ii,jj).pkexp);
                if npks >0
                    %available peaks to assign
                    npkavail = min(arg.ntag, npks);
                    % exp, cnt, pct
                    % default expression is median
                    pkexp = pkstats(ii,jj).medexp * ones(arg.ntag, 1);
                    pksupport = zeros(arg.ntag, 1);
                    pksupport_pct = zeros(arg.ntag, 1);
                    % assign available peaks
                    pkexp(1:npkavail) = pkstats(ii,jj).pkexp(1:npkavail);
                    pksupport(1:npkavail) = pkstats(ii,jj).pksupport(1:npkavail);
                    pksupport_pct(1:npkavail) = pkstats(ii,jj).pksupport_pct(1:npkavail);
                    %check support
                    nosup = find(pksupport < arg.min_support | pksupport_pct < arg.min_support_pct);
                    % if no support assign first peak and split support
                    if ~isempty(nosup)
                        % Note only works for ntag=2
                        pkexp(nosup) = pkstats(ii,jj).pkexp(1);
                        pksupport(1:arg.ntag) = floor(pkstats(ii, jj).pksupport(1) / arg.ntag);
                        pksupport_pct(1:arg.ntag) = 100 * pksupport / max(1, pkstats(ii,jj).ngoodbead);
                    end
                    for p = 1:arg.ntag
                        ds(p).mat(ii, jj) = pkexp(p);
                        ds(p).support(ii, jj) = pksupport(p);
                        ds(p).support_pct(ii, jj) = pksupport_pct(p);
                    end
                end
        end
    end
end