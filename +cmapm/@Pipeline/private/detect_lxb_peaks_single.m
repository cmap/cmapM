function pkstats = detect_lxb_peaks_single(x, varargin)
% DETECT_LXB_PEAKS_SINGLE Detect peaks for a single analyte in lxb data.
%   PKSTATS = DETECT_LXB_PEAKS_SINGLE(X) detect peaks for intensities X. X
%   is a 1d vector of fluorescent intensities. PKSTATS is a structure array
%   with the detected peaks and support information.
%
%   PKSTATS = DETECT_LXB_PEAKS_SINGLE(X, 'Param1, 'Value1',...)
%   Specify optional parameters to peak detection routine.
%
%   logxform : log2 transform the data before detecting peaks. Logical [true]
%   lowthresh : log2 lower threshold for expression. Double [4]
%   highthresh : log2 upper threshold for expression. Double [14]
%   showfig : Display figure showing detected peaks. Logical [false]
%   sortbyht : Sort peaks by height. Logical [true]
%   ksmethod : Kernel smoothening method. String {['ksdensity'],'kde'}
%   minbead : Minimum good beads to make a call. Integer [20]
%   pkmethod : Peak calling method. String {'kspeak','kmeans','kmopt','gmm}
%   ncomp : Number of components to detect. Integer [2]
%   merge_close_peaks : Merge peaks that are close together when using
%       kmeansopt. Logical [true]
%   debug : Print degging info. Logical [true] 
%
%   See also: DETECT_LXB_PEAKS_FOLDER, DETECT_LXB_PEAKS_MULTI

toolName = mfilename;
    
pnames = {'debug', ...
    'highthresh', ...
    'ksmethod', ...
    'logxform', ...
    'lowthresh', ...
    'max_k', ...
    'merge_close_peaks', ...
    'minbead', ...
    'min_peak_support', ...
    'min_peak_support_pct', ...
    'ncomp', ...
    'opt_support_pct', ...
    'out', ...
    'overwrite', ...
    'pkmethod', ...
    'rpt', ...
    'savefig', ...
    'showfig', ...
    'sortbyht', ...
    'subtractbg', ...
    'title'};

dflts = { false, ...
    14, ...
    'ksdensity',...
    true, ...
    4, ...
    4, ...
    true, ...
    20, ...
    10, ...
    10, ...
    2, ...
    [65 35], ...
    pwd, ...
    false, ...
    'kspeak', ...    
    'hist', ...      
    false, ...
    false, ...
    false, ...
    false, ...
    ''};    

arg = parse_args(pnames, dflts, varargin{:});
% print_args(toolName, 1, arg);

nbead = length(x);

%s=init_rand_state;

%convert x to log scale
if (arg.logxform)
    x = safe_log2(x - arg.subtractbg);
end

%censor beads with high / low expression
badbeads = (x < arg.lowthresh | x > arg.highthresh);
xcensored=x;
xcensored(badbeads)=[];
ngoodbead = length(xcensored);

%default value is median of good beads
medexp = median(xcensored);
if (arg.logxform)
   medexp = round(pow2(medexp));
end
% bad or missing data defaults to one (zero on log scale)
if isempty(medexp) || isnan(medexp) || isequal(nbead,0)
    medexp = 1;
end

%default stats
pkstats =  struct('pkexp', medexp,...
    'pksupport', ngoodbead, 'pksupport_pct',100,'pkheight', 1,...
    'totbead', nbead, 'ngoodbead', ngoodbead,...
    'medexp', medexp, ...
    'method','median');

if (ngoodbead < arg.minbead || isequal(arg.ksmethod, 'median'))
    % dont detect peaks just return default
    if arg.showfig
        hf = myfigure(~arg.savefig);
        bins = linspace(4, 16, 50);
        [a0,b0] = hist(x, bins); 
        bar(b0,a0/max(a0), 'facecolor',[0.75,0.75,0.75])
        hold on
        [a, b] = hist(xcensored, bins);
        bh = bar(b,a/max(a), 'hist');
        % color brewer PuOr scheme
        purple = [153, 142, 195]/255;
        orange = [241, 163, 64]/255;
        set (bh, 'facecolor', orange)
        keep = 1:min(4, length(pkstats.pkexp));
        expstr = print_dlm_line(pkstats.pkexp(keep), 'dlm', ', ', 'precision', 1);
        supstr = print_dlm_line(pkstats.pksupport(keep), 'dlm', ', ', 'precision', 0);
        suppctstr = print_dlm_line(pkstats.pksupport_pct(keep),'dlm',', ','precision',0);        
        xlim ([4, 15])
        h = title(texify(sprintf('%s n=%d exp:(%s) sup:(%s) pct:(%s)', ...
            arg.title, pkstats.ngoodbead, expstr, supstr, suppctstr)));
        set(h,'fontweight','bold','fontsize',11)
        namefig(arg.rpt);
        if arg.savefig
            savefigures('out', arg.out, 'mkdir', false, 'overwrite', arg.overwrite);
            close(hf)
        end
    end
else
    dbg(arg.debug, arg.pkmethod);
    switch (arg.pkmethod)
        case 'kspeak'
            switch (lower(arg.ksmethod))
                % kernel density
                case 'ksdensity'
                    [f, xi]=ksdensity(xcensored);
                    %             [f, xi]=ksdensity(xcensored,'width',0.1437);
                case 'kde'
                    [bw, f, xi] = kde(xcensored);
                    disp(bw)
                otherwise
                    error ('Unknown ksmethod:%s',arg.ksmethod)
            end
            
            % [f, xi]=ksdensity(x, 'censoring', badbeads);
            % % kde from matlab fileexchange
            % xcensored = x;
            % xcensored(badbeads)=[];
            % [bw, f, xi] = kde(xcensored);
            
            [pkfreq, locs] = findpeaks(f, 'sortstr', 'descend', 'minpeakheight', 0.0001);
            
            if ~isempty(pkfreq)
                
                
                % force at least two peaks
                % if npks == 1
                %     pkfreq(2) = pkfreq(1);
                %     locs(2) = locs(1);
                %     npks=2;
                % end
                
                % expression value for each peak [expression values]
                pkexp = xi(locs);
                
                
                npks = length(pkfreq);
               
                % count support beads
                % %distance from each peak
                % disthigh = sqrt((x(~badbeads) - allpeaks(1)).^2);
                % distlow = sqrt((x(~badbeads) - allpeaks(2)).^2);
                % nlowbead = nnz(distlow < disthigh);
                % nhighbead = nnz(disthigh < distlow);
                
                % sqeuclidean dist of each bead from each peak
                D = zeros(nnz(~badbeads), npks);
                for ii=1:npks
                    D(:,ii) = (x(~badbeads) - pkexp(ii)).^2;
                end
                
                %num bead supporting each peak
                % assign each good bead to the nearest peak
                [mindist, pkidx] = min(D, [], 2);
                pksupport = accumarray(pkidx, ones(size(pkidx)))';
                
                if arg.sortbyht
                    %sort by height [default]
                    [srt_pkheight, supidx] = sort(pkfreq, 'descend');
                    srt_pkexp = pkexp(supidx);
                    srt_pksup = pksupport(supidx);
                else
                    %sort peaks by support
                    [srt_pksup, supidx] = sort(pksupport, 'descend');
                    srt_pkexp = pkexp(supidx);
                    srt_pkheight = f(locs(supidx));
                end
                
                %percentage of good bead that support each peak
                srt_pksup_pct = 100*srt_pksup/sum(srt_pksup);
                
                pkstats = struct(...
                    'pkexp', srt_pkexp,...
                    'pksupport', srt_pksup,...
                    'pksupport_pct',srt_pksup_pct,...
                    'pkheight', srt_pkheight,...
                    'totbead', nbead,...
                    'ngoodbead', ngoodbead,...
                    'medexp', medexp,...
                    'method', arg.pkmethod);
                
            end
        case 'gmm'
            
            gmfit = @gmdistribution.fit;
            gmopt = statset('MaxIter', 250);
            gmmobj = gmfit(xcensored, arg.ncomp, 'Regularize', 1e-15 ,'Options', gmopt);
            pkexp = gmmobj.mu';
            pksup_pct = 100*gmmobj.PComponents;
            pksup = round(ngoodbead*pksup_pct/100);
            
            % compute smoothed kernel, lookup pk heights
            [f, xi]=ksdensity(xcensored);
            pkheight = interp1(xi,f, pkexp);
            
            [srt_pksup_pct, srtidx] = sort(pksup_pct,'descend');
            srt_pkexp = pkexp(srtidx);
            srt_pkheight = pkheight(srtidx);
            srt_pksup = pksup(srtidx);
            
            pkstats = struct(...
                'pkexp', srt_pkexp,...
                'pksupport', srt_pksup,...
                'pksupport_pct', srt_pksup_pct,...
                'pkheight', srt_pkheight,...
                'totbead', nbead,...
                'ngoodbead', ngoodbead,...
                'method', arg.pkmethod);
        case 'kmeans'
            [idx, c, sumd, d] = kmeans(xcensored, arg.ncomp, 'emptyaction','drop','replicates',10);
            % median of clusters instead of the mean
            for ii=1:arg.ncomp
                pkexp(1,ii) = median(xcensored(idx==ii));
            end
            
            pksup = accumarray(idx,ones(size(idx)))';
            pksup_pct = 100*pksup/ngoodbead';
            
            % compute smoothed kernel, lookup pk heights
            [f, xi]=ksdensity(xcensored);
            pkheight = interp1(xi,f, pkexp);
            [srt_pksup_pct, srtidx] = sort(pksup_pct, 'descend');
            srt_pkexp = pkexp(srtidx);
            srt_pkheight = pkheight(srtidx);
            srt_pksup = pksup(srtidx);
            
            pkstats = struct(...
                'pkexp', srt_pkexp,...
                'pksupport', srt_pksup,...
                'pksupport_pct', srt_pksup_pct,...
                'pkheight', srt_pkheight,...
                'totbead', nbead,...
                'ngoodbead', ngoodbead,...
                'medexp', medexp,...
                'method', arg.pkmethod);

        case 'kmeansopt'
            % turn off emptycluster warning
            warning('off', 'stats:kmeans:EmptyCluster')
            sd = zeros(4,1);
            sd(1) = sum((xcensored-mean(xcensored)).^2);
            for k=2:4
                [idx, c, sumd, d] = kmeans(xcensored, k, 'emptyaction','drop','replicates', 3);
                sd(k) = sum(sumd);
            end
            pctsd = (sd(1)-sd)/sd(1);
            optk = find(pctsd > 0.80, 1, 'first');
            if isempty(optk)
                optk = 2;
            end
            
            dbg(arg.debug, 'optk=%d, pctsd=%2.2f\n', optk, pctsd(optk));            
            [idx, c, sumd, d] = kmeans(xcensored, optk, 'emptyaction','drop','replicates', 5);
            
            %merge_close_peaks=1;
            if arg.merge_close_peaks
                % minimum distance between peaks [log2]
                MIN_PEAK_DIST=0.5;
                %sort centroids
                [srtc,srtidx]=sort(c,'descend');
                lastidx=1;
                clast=srtc(1);
                newidx=zeros(size(idx));
                newc=zeros(size(c));
                %make lowest centroid the first cluster
                newidx(idx==srtidx(1))=1;
                newc(1)=srtc(1);
                newoptk=1;
                for ii=2:optk
                    % merge centers
                    %if ((srtc(ii) - newc(newoptk)) < MIN_PEAK_DIST)
                    if ((newc(newoptk) - srtc(ii)) < MIN_PEAK_DIST)
                        newidx(idx==srtidx(ii))=newoptk;
                        newc(newoptk)=0.5*(newc(newoptk)+srtc(ii));
                    else
                        newoptk=newoptk+1;
                        newidx(idx==srtidx(ii)) = newoptk;
                        newc(newoptk) = srtc(ii);
                    end
                end
                idx=newidx;
                c=newc;
                optk=newoptk;
                dbg(arg.debug, 'newoptk:%d\n', optk);
            end
            
            % median of clusters instead of the mean
            for ii=1:optk
                pkexp(1,ii) = median(xcensored(idx==ii));
            end
            
            pksup = accumarray(idx,ones(size(idx)))';
            pksup_pct = 100*pksup/ngoodbead';
            
            % compute smoothed kernel, lookup pk heights
            [f, xi]=ksdensity(xcensored);
            pkheight = interp1(xi,f, pkexp);
            [srt_pksup_pct, srtidx] = sort(pksup_pct, 'descend');
            srt_pkexp = pkexp(srtidx);
            srt_pkheight = pkheight(srtidx);
            srt_pksup = pksup(srtidx);
            
            pkstats = struct(...
                'pkexp', srt_pkexp,...
                'pksupport', srt_pksup,...
                'pksupport_pct', srt_pksup_pct,...
                'pkheight', srt_pkheight,...
                'totbead', nbead,...
                'ngoodbead', ngoodbead,...
                'medexp', medexp,...
                'method', arg.pkmethod);
            
        case 'kmeans_dev'
            %OPT_RATIO = 1.85;
            %OPT_SUPPORT_PCT = [65 35];
            % turn off emptycluster warning
            warning('off', 'stats:kmeans:EmptyCluster')
            sd = zeros(4, 1);
            sup_ratio = zeros(4, 1);
            sup_pct = zeros(4, 1);
            sd(1) = sum((xcensored-mean(xcensored)).^2);
            sup_pct(1) = sum(abs([100 0]-arg.opt_support_pct));
            for k=2:4
                [idx, c, sumd, d] = kmeans(xcensored, k, 'emptyaction','drop','replicates', 3);
                if nnz(~isnan(c)) == 1
                    continue
                end
                sup = accumarray(idx, ones(size(idx)))';                
                srtsup = sort(sup, 'descend');
                sd(k) = sum(sumd);
                sup_ratio(k) = (srtsup(1)/ngoodbead) ./ (srtsup(2)/ngoodbead);
                sup_pct(k) = sum(abs(100*srtsup(1:2)/ngoodbead - arg.opt_support_pct));
            end
%             pick optimal k
%             pctsd = (sd(1)-sd)/sd(1);
%             optk = find(pctsd > 0.80, 1, 'first');            
%             [~, optk] = min(abs(sup_ratio - OPT_RATIO));
            [~, optk] = min(sup_pct);
            if isempty(optk)
                optk = 2;
            end            
            dbg(arg.debug, 'optk=%d, pctdiff=%2.2f ratio=%2.2f sd=%2.2f\n', ...
                optk, sup_pct(optk), sup_ratio(optk), sd(optk));
%             disp(supmat)
%             disp(cmat)
            [idx, c, sumd, d] = kmeans(xcensored, optk, 'emptyaction','singleton','replicates', 5);
            
            %merge_close_peaks=1;
            if arg.merge_close_peaks
                % maximum separation between centers that are merged
                MAX_PEAK_DIST = 0.5;
                %get peaks using kspeak
                kpk = detect_lxb_peaks_single(pow2(x), 'pkmethod', 'kmeans', ...
                    'lowthresh', arg.lowthresh, 'highthresh', arg.highthresh);
                logpk = sort(log2(kpk.pkexp),'descend');
                                
                %sort centroids
                % handle empty clusters
                if any(isnan(c))
                    disp('Dropping empty cluster')
                    c = c(~isnan(c));
                    optk = length(c);
                    [~, idx] = getcls(idx);
                end

                [srtc, srtidx] = sort(c, 'descend');
                newidx = zeros(size(idx));
                newc = zeros(size(c));
                % support for each centroid
                support_pct = 100 * accumarray(idx, ones(size(idx)))' / ngoodbead;
                support_pct = support_pct(srtidx);
                %make lowest centroid the first cluster
                newidx(idx==srtidx(1)) = 1;
                newc(1) = srtc(1);
                newoptk = 1;
                for ii=2:optk
                    % merge centers
                    d1 = newc(newoptk) - logpk;
                    [~, idx1] = min(abs(d1));
                    sign1 = sign(d1(idx1));
                    sup1 = support_pct(newoptk);
                    
                    d2 = srtc(ii) - logpk;                    
                    [~, idx2] = min(abs(d2));
                    sign2 = sign(d2(idx2));
                    sup2 = support_pct(ii);
                    
                    if idx1==idx2 && sign1 ~= sign2 && ((newc(newoptk) - srtc(ii)) < MAX_PEAK_DIST)                        
                        newidx(idx==srtidx(ii)) = newoptk;
                        newc(newoptk) = 0.5*(newc(newoptk)+srtc(ii));
                    else
                        newoptk = newoptk + 1;
                        newidx(idx==srtidx(ii)) = newoptk;
                        newc(newoptk) = srtc(ii);
                    end
                end
                idx=newidx;
                c=newc;
                optk=newoptk;
                printdbg(sprintf ('newoptk:%d\n',optk), arg.debug);
            end
            
            % median of clusters instead of the mean
            for ii=1:optk
                pkexp(1,ii) = median(xcensored(idx==ii));
            end
            
            pksup = accumarray(idx,ones(size(idx)))';
            pksup_pct = 100*pksup/ngoodbead';
            
            % compute smoothed kernel, lookup pk heights
            [f, xi]=ksdensity(xcensored);
            pkheight = interp1(xi,f, pkexp);
            [srt_pksup_pct, srtidx] = sort(pksup_pct, 'descend');
            srt_pkexp = pkexp(srtidx);
            srt_pkheight = pkheight(srtidx);
            srt_pksup = pksup(srtidx);
            
            pkstats = struct(...
                'pkexp', srt_pkexp,...
                'pksupport', srt_pksup,...
                'pksupport_pct', srt_pksup_pct,...
                'pkheight', srt_pkheight,...
                'totbead', nbead,...
                'ngoodbead', ngoodbead,...
                'medexp', medexp,...
                'method', arg.pkmethod);
            
        case 'kmeans_viable'
            % turn off emptycluster warning
            warning('off', 'stats:kmeans:EmptyCluster')
            warning('off', 'stats:kmeans:EmptyClusterRep')
            % optimal K
            best_k = 1;
            % centroids
            best_c = log2(medexp);
            % cluster identity for each K
            best_idx = ones(ngoodbead, 1);            
            % diff between measured and ideal support pct
            best_sup_dist = sum(abs([100 0] - arg.opt_support_pct));
            % Pick an optimal k
            for k=2:arg.max_k
                [idx, c, sumd, d] = kmeans(xcensored, k, ...
                    'emptyaction', 'drop', 'replicates', 5);                
                nc = nnz(~isnan(c));
                if nc < 2
                    % NaN centroids found, skip
                    dbg(arg.debug, 'k=%d NaN centroids found, skipping', k)
                    continue                    
                else
                    sup = accumarray(idx, ones(size(idx)))';
                    srtsup = sort(sup, 'descend');
                    sup_dist = sum(abs(100 * srtsup(1:2) / ngoodbead - arg.opt_support_pct));
                    isviable = sup >= arg.min_peak_support & 100*sup/ngoodbead >= arg.min_peak_support_pct;
                    nviable = sum(isviable);
                    if nviable > 1 && (sup_dist < best_sup_dist)
                        best_sup_dist = sup_dist;                        
                        best_idx = idx;
                        best_c = c;
                        best_c(~isviable) = nan;
                        best_k = nviable;
                    end
                end
            end
            
            % Keep viable clusters
            if nnz(isnan(best_c))
                keep = find(~isnan(best_c));
                best_c = best_c(keep);                
                tmp_idx = nan(ngoodbead, 1);
                for ii=1:best_k                    
                    tmp_idx(best_idx==keep(ii)) = ii;
                end
                % censor non-viable clusters
                valid_beads = ~isnan(tmp_idx);
                xcensored = xcensored(valid_beads);
                best_idx = tmp_idx(valid_beads);
                ngoodbead = nnz(valid_beads);
            end
                        
            dbg(arg.debug, 'optk=%d, sup_dist=%2.2f\n', ...
                best_k, best_sup_dist);

            pksup = accumarray(best_idx, ones(size(best_idx)))';
            pksup_pct = 100*pksup/ngoodbead';
            % median of clusters instead of the mean
            pkexp = zeros(1, best_k);
            for ii=1:best_k
                pkexp(1, ii) = median(xcensored(best_idx==ii));
            end
                        
            % compute smoothed kernel, lookup pk heights
            [f, xi] = ksdensity(xcensored);
            pkheight = interp1(xi, f, pkexp);
            [srt_pksup_pct, srtidx] = sort(pksup_pct, 'descend');
            srt_pkexp = pkexp(srtidx);
            srt_pkheight = pkheight(srtidx);
            srt_pksup = pksup(srtidx);
            
            pkstats = struct(...
                'pkexp', srt_pkexp,...
                'pksupport', srt_pksup,...
                'pksupport_pct', srt_pksup_pct,...
                'pkheight', srt_pkheight,...
                'totbead', nbead,...
                'ngoodbead', ngoodbead,...
                'medexp', medexp,...
                'method', arg.pkmethod);
        otherwise
            error('Unknown pkmethod:%s',arg.pkmethod)            
            
    end
    
    if arg.showfig
        hf = myfigure(~arg.savefig);
        bins = linspace(4, 16, 50);
        [a0,b0] = hist(x, bins); 
        bar(b0,a0/max(a0), 'facecolor',[0.75,0.75,0.75])
        hold on
        [a, b] = hist(xcensored, bins);
        bh = bar(b,a/max(a), 'hist');
        % color brewer PuOr scheme
        purple = [153, 142, 195]/255;
        orange = [241, 163, 64]/255;
        set (bh, 'facecolor', orange)
        th = text(srt_pkexp+0.05, srt_pkheight+0.05, num2cellstr(1:length(srt_pkexp)));
        set(th,'color', 'k', 'fontsize', 16, 'fontweight', 'bold', ...
            'backgroundcolor', [.7 .9 .7])
        plot(xi, f, 'k', 'linewidth', 2)
        plot(srt_pkexp, srt_pkheight, 'ko','markerfacecolor', 'c', 'markersize', 7)
        keep = 1:min(4, length(pkstats.pkexp));
        expstr = print_dlm_line(pkstats.pkexp(keep), 'dlm', ', ', 'precision', 1);
        supstr = print_dlm_line(pkstats.pksupport(keep), 'dlm', ', ', 'precision', 0);
        suppctstr = print_dlm_line(pkstats.pksupport_pct(keep),'dlm',', ','precision',0);        
        xlim ([4, 15])
        h = title(texify(sprintf('%s n=%d exp:(%s) sup:(%s) pct:(%s)', ...
            arg.title, pkstats.ngoodbead, expstr, supstr, suppctstr)));
        set(h,'fontweight','bold','fontsize',11)
        ylabelrt(texify(arg.rpt), 'color', 'b');
        namefig(arg.rpt);
        if arg.savefig
            savefigures('out', arg.out, 'mkdir', false, 'overwrite', arg.overwrite);
            close(hf)
        end
    end
    
    % convert expression to linear scale
    if (arg.logxform)
        %pkstats.log2pkexp = pkstats.pkexp;
        pkstats.pkexp = round(pow2(pkstats.pkexp));        
%         pkstats.medexp = round(pow2(pkstats.medexp));   
    end
                
end

end

