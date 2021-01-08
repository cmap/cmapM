function [ps, stats] = scoreToPercentileTransform(ncs, dim, min_val, max_val, nbins, varargin)
% scoreToPercentileTransform Compute scores to percentile transformation.
% ps = scoreToPercentileTransform(score, dim, min_val, max_val, nbins)

pnames = {'method'};
dflts = {'symmetric'};
arg = parse_args(pnames,dflts,varargin{:});
[dim_str, dim_val] = get_dim2d(dim);

if isequal(dim_str, 'column')
    nsig = size(ncs.mat, 2);
    rid = ncs.cid;    
else
    nsig = size(ncs.mat, 1);
    rid = ncs.rid;
end

% bins, range of normalized scores
% nbins = 10001;
vq = linspace(min_val, max_val, nbins)';
vqz = ceil(nbins/2);

% ns2rp lookup table one curve per row in ns
tx = zeros(nsig, nbins);
% Stats
st_cid = {'npos', 'nneg', 'nz',...
          'pos_mean', 'neg_mean',...
          'pos_std', 'neg_std'};
st = zeros(nsig, numel(st_cid));
for ii=1:nsig
    if isequal(dim_str, 'column')
        x = ncs.mat(:, ii);
    else
        x = ncs.mat(ii, :);
    end
    switch lower(arg.method)
        case 'global'
            [f, v] = cdfcalc(x);
            % percentile ranks in descending order
            r = 100-f*100;
            % clip the ranks of positive and negative scores that cross 50th
            % percentile
            posv = find(v>0);
            r(posv(r(posv)>50)) = 50;    
            negv = find(v<0);
            r(negv(r(negv)<50)) = 50;
            % Stats
            posx = x(x>0);
            negx = x(x<0);
            % npos
            st(ii, 1) = numel(posx);
            % nneg
            st(ii, 2) = numel(negx);
            % nz
            st(ii, 3) = numel(x) - (st(ii, 1) + st(ii, 2));
            % pos mean
            st(ii, 4) = mean(posx);
            % neg mean
            st(ii, 5) = mean(negx);
            %pos std
            st(ii, 6) = std(posx);
            %neg std
            st(ii, 7) = std(negx);
            
            % convert percentiles to rankpoints
            r = 2*(50-r);
            if all(isnan(r))
                error('Percentile compute issue for sig index:%d',ii) 
            end
            % Linearly interpolate over full range of vq 
            rq = interp1(v, r(1:end-1), vq, 'nearest');

            % negative score closest to zero
            zn = max(x(x<0));
            % positive score closest to zero
            zp = min(x(x>0));
            if isempty(zn)
                zn = zp;
            end
            if isempty(zp)
                zp = zn;
            end

            % find null regions
            % find nearest vq index
            vqidx = interp1(vq, 1:length(vq), [zn, zp], 'nearest');
            if numel(vqidx)<2
                error('Error computing null region sig index: %d', ii);
            end
            xn = vq(vqidx(1));
            % find nearest rq
            yn = interp1(vq, rq, xn, 'nearest');
            % do the same for positive scores
            xp = vq(vqidx(2));
            yp = interp1(vq, rq, xp, 'nearest');

            % linearly interpolate the null regions
            nidx = vqidx(1):vqz;
            pidx = vqz:vqidx(2);        
            rq(nidx) = yn*vq(nidx)/xn;
            rq(pidx) = yp*vq(pidx)/xp;

            % Set NaNs to max
            inan = isnan(rq);
            rq(inan) = sign(vq(inan))*100;    
            
            % store transform values
            tx(ii, :) = rq;        
            % print_ticker(ii, 25, nsig, round(0.5*nsig/100));
        
        case 'decoupled'
            % Negative scores
            negx = x(x<0);
            negvqi = vq<0;
            negvq = vq(negvqi);
            [negf, negv] = cdfcalc(negx);
            negr = 100*(negf-1);
            negrq = interp1(negv, negr(1:end-1), negvq, 'nearest');

            %set out-of-range regions to -100 or 0 as appropriate
            negrq(negvq < negv(1)) = -100;
            negrq(negvq > negv(end)) = 0;
            
            %store negative transform values
            tx(ii, negvqi) = negrq;

            % Positive scores
            posx = x(x>0);
            posvqi = vq>0;
            posvq = vq(posvqi);
            [posf, posv] = cdfcalc(posx);
            posr = 100*posf;
            posrq = interp1(posv, posr(1:end-1), posvq, 'nearest');

            %set out-of-range regions to +100 or 0 as appropriate
            posrq(posvq < posv(1)) = 0;
            posrq(posvq > posv(end)) = 100;
            
            %store positive transform values
            tx(ii, posvqi) = posrq;

            %store stats
            st(ii, 1) = numel(posx);
            st(ii, 2) = numel(negx);
            st(ii, 3) = numel(x) - (st(ii, 1) + st(ii, 2));
            st(ii, 4) = mean(posx);
            st(ii, 5) = mean(negx);
            st(ii, 6) = std(posx);
            st(ii, 7) = std(negx);
        case 'symmetric_nozero'
            posx = x(x>0);
            negx = x(x<0);
            % use absolute scores
            x = abs(x);
            % percentiles of non-zero scores
            nzx = x(x>0);
           
            [nzf, nzv] = cdfcalc(nzx);
            % scale to [0, 100]
            nzr = 100*nzf;
            rq = zeros(size(vq));
            posvq = vq>0;
            negvq = vq<0;
            rq(posvq) = interp1(nzv, nzr(1:end-1), vq(posvq), 'nearest');
            rq(negvq) = interp1(-nzv, -nzr(1:end-1), vq(negvq), 'nearest');
            %set out-of-range regions to -100, 0 or +100 as appropriate
            maxima = abs(vq)>nzv(end);
            rq(maxima) = sign(vq(maxima))*100;
            minima = abs(vq)<nzv(1);
            rq(minima) = 0;
                    
            %store transform values
            tx(ii, :) = rq;

            %store stats
            st(ii,1) = numel(posx);
            st(ii,2) = numel(negx);
            st(ii,3) = numel(x) - (st(ii, 1) + st(ii, 2));
            st(ii,4) = mean(posx);
            st(ii,5) = mean(negx);
            st(ii, 6) = std(posx);
            st(ii, 7) = std(negx);
            
        case 'symmetric'
            posx = x(x>0);
            negx = x(x<0);
            % use absolute scores
            x = abs(x);           
            [f, v] = cdfcalc(x);
            % scale to [0, 100]
            r = 100*f;
            rq = zeros(size(vq));
            posvq = vq>0;
            negvq = vq<0;
            rq(posvq) = interp1(v, r(1:end-1), vq(posvq), 'nearest');
            rq(negvq) = interp1(-v, -r(1:end-1), vq(negvq), 'nearest');
            %set out-of-range regions to -100, 0 or +100 as appropriate
            maxima = abs(vq)>v(end);
            rq(maxima) = sign(vq(maxima))*100;
            
            % interpolate null through zero
            vqidx = find(vq<v(2), 1, 'last');
            % slope of line through zero
            m = rq(vqidx)/vq(vqidx);
            null_idx = abs(vq) < vq(vqidx);
            rq(null_idx) = vq(null_idx)*m;
                    
            %store transform values
            tx(ii, :) = rq;

            %store stats
            st(ii,1) = numel(posx);
            st(ii,2) = numel(negx);
            st(ii,3) = nnz(~isnan(x)) - (st(ii, 1) + st(ii, 2));
            st(ii,4) = mean(posx);
            st(ii,5) = mean(negx);
            st(ii, 6) = std(posx);
            st(ii, 7) = std(negx);
    end
end

tx_labels = gen_labels(size(tx, 2), 'prefix', 'x');
ps = mkgctstruct(tx, 'rid', rid, 'cid', tx_labels);
stats = mkgctstruct(st, 'rid', rid, 'cid', st_cid);
ps = ds_add_meta(ps, 'column', {'bin_center'}, num2cell(vq));
end
