function th = smart_text(x,y, lbl, opt, varargin)
% SMART_TEXT Arrange text labels smartly.
%   TH = SMART_TEXT(X, Y, LBL, OPT,...)
th = [];
nin = nargin;
if nin <3
    error('Invalid number of inputs')
elseif nin>=3
    OPT = struct('start_temp',1,...
        'debug', 0,...
        'jitter', 1);
    if nin>3
        if isstruct(opt)
            fn = fieldnames(opt);
            for ii=1:length(fn)
                if isfield(OPT, fn{ii})
                    OPT.(fn{ii})  = opt.(fn{ii});
                else
                    error('Unknown option: %s', fn{ii})
                end
            end
        elseif ~isempty(opt)
            error('Opt should either be empty or a struct');
        end
    end
end
n = length(x);
if (n>0 && length(y)==n && length(lbl)==n)
    if all(ishandle(x)) && isempty(y)
        % text handles supplied
        th  = x;
        pos = get(th,'position');
        if iscell(pos)
            init_pos=cell2mat(pos);
        else
            init_pos = pos;
        end
    else
        th = text(double(x), double(y), lbl, varargin{:});
        set(gcf, 'renderer', 'opengl')
        init_pos = [x(:),y(:)];
    end
    % init_pos=cell2mat(get(th,'position'));
    %rectangle extents [left, bottom, width, height]
    extents = get(th,'extent');
    if iscell(extents)
        rect=cell2mat(extents);
    else
        rect = extents;
    end
    %overlaps
    ov = rectint(rect, rect);
    areas = sqrt(diag(ov));
    pctov = bsxfun(@rdivide, ov, areas);
    pctov = bsxfun(@rdivide, pctov, areas'/100);
    keepidx = find (triu(true(n), 1));
    [r,c]=ind2sub(size(ov), keepidx);
    obj =  sum(pctov(keepidx))/n;
    % initial position and objective fn
    init_obj=obj;
    
    %original alignments
    hpos = get(th,'horizontalalignment');
    vpos = get(th,'verticalalignment');
    a = {'horizontalalignment', 'verticalalignment', 'rotation'};
    % v = {'left', 'right', 'center', 'top', 'bottom', 'middle'};
    % p = a([1,1,1,2,2,2]);
    % v = {'left', 'right', 'center', 'top', 'bottom', 'middle', 0, 90,-90};
    % p = a([1,1,1,2,2,2,3,3,3]);
    v = {'left', 'right',  'top', 'bottom', 'middle'};
    p = a([1,1,2,2,2]);
    % v = {'left', 'right',  'top', 'bottom', 'middle', -90, -45 ,0, 45, 90};
    % p = a([1,1,2,2,2,3*ones(1,5)]);
    
    npos = length(p);
    
    % temp is set so that P = 2/3 when deltaE is 1
    % T=-1/log(1/3);
    T=1;
    %P = 1-exp(-1/T);
    %maximum temp changes
    max_t_change = 50;
    % maximum repositionings at a given T
    max_tries = 40*npos;
    % maximum changes at a given T
    max_success = 5*npos;
    % change in temp
    deltaT = 0.9;
    
    % number of temp changes
    nt = 0;
    % number of successful changes
    nsuccess = 0;
    % minimum obj
    % min_obj = 1e-3;
    bestval = cell(n,1);
    bestprop = cell(n,1);
    bestpos = init_pos;
    
    bestobj = obj;
    lastobj = obj;
    tic
    % new solution
    % newsol = @(x)(randsample(npos, 1));
    % cooling schedule
    cool = @(T) (deltaT*T);
    cand = find(pctov(keepidx));
    cand = [r(cand); c(cand)];
    done = isempty(cand);
    % keyboard
    while ~done
        %pick a random label
        ridx = randsample(cand, max_tries, true);
        %reposition it
        sols = randsample(npos, max_tries, true);
        for ii=1:max_tries
            newpos = sols(ii);
            newdim = p{newpos};
            newalign = v{newpos};
            oldalign = get(th(ridx(ii)), newdim);
            oldpos = get(th(ridx(ii)), 'position');
            % add position jitter
            if OPT.jitter
                [jx,jy] = randcircle(1, init_pos(ridx(ii), 1:2), rect(1,4)/4);
                set(th(ridx(ii)),'position',[jx,jy])
            end
            set(th(ridx(ii)), newdim, newalign)
            
            %recompute objective fn
            thisrect = get(th(ridx(ii)), 'extent');
            newrect = rect;
            newrect(ridx(ii),:) = thisrect;
            newpctov = pctov;
            this_ov = rectint(thisrect, newrect);
            this_pctov = this_ov/areas(ridx(ii));
            this_pctov = 100 * this_pctov./areas';
            newpctov(ridx(ii), :) = this_pctov;
            newpctov(:, ridx(ii)) = this_pctov;
            newobj =  sum(newpctov(keepidx))/n;
            cand = find(newpctov(keepidx));
            cand = [r(cand); c(cand)];
            deltaE = 100*(obj - newobj)/obj;
            if deltaE>1e-6 || (rand < exp(deltaE/T) && deltaE<0)
                nsuccess = nsuccess + 1;
                obj = newobj;
                rect = newrect;
                pctov = newpctov;
                if OPT.debug
                    drawnow
                end
                %             fprintf('%d obj:%f deltaE:%f nsuccess:%d \n',ii, obj, deltaE, nsuccess);
            else
                %             fprintf('deltaE:%f P:%f undo\n',deltaE, P);
                set(th(ridx(ii)), newdim, oldalign);
                set(th(ridx(ii)), 'position', oldpos);
            end
            
            %         % metaheuristic: track best solution
            %         if obj<bestobj
            %             bestobj = obj;
            %             bestpos(ridx(ii),1:2) = [jx, jy];
            %             bestval{ridx(ii)}=newalign;
            %             bestprop{ridx(ii)}=newdim;
            %         end
            if nsuccess >= max_success
                % temp is decreased if many successful changes.
                break
            end
        end
        
        nt = nt+1;
        T = cool(T);
        delta = 100*(lastobj - bestobj)/lastobj;
        done =  nt>max_t_change || (nsuccess==0 && ii==max_tries)||isempty(cand)||delta<1e-6;
        if OPT.debug
            fprintf ('%d/%d T:%f obj:%f improvement:%f success:%d tries:%d\n', nt, max_t_change, T, obj, delta, nsuccess, ii);
        end
        nsuccess = 0;
        lastobj = bestobj;
    end
    
    % for ii=1:n
    %     if ~isempty(bestprop{ii})
    %         set(th(ii), bestprop{ii}, bestval{ii})
    %         set(th(ii), 'position', bestpos(ii,:));
    %     end
    % end
    if OPT.debug
        fprintf('best obj: %f improvement: %f\n', bestobj, 100*(init_obj-bestobj)/init_obj)
        fprintf('done %2.2fsecs\n', toc)
    end
end

end