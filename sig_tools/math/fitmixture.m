function [muVals,mixing,params,iter,responsibility] = fitmixture(sig,method,params)
% FITMIXTURE    Primary peak calling algorithm for dual tag data
%   [muVals,mixing,params,iter,responsibility] =
%   fitmixture(sig,method,params) will make a duo - mode call in the signal
%   'sig' using 'method' and given initial parameters 'params'. 
%   Inputs: 
%       sig : a vector of data. If length(sig) < 5, then no computation is
%       carried out, and peak calls are set to zero. If length(sig) < 30,
%       then the median is computed. 
%       method : only EM based gaussian fit works. If method ='gibbs', then
%       a gibbs sampling EM approach is used but this is still in
%       development. By default method ='direct', i.e. EM based gaussian
%       fit. 
%       params : a structure with fieldnames 'mu', 'sigma', and 'mixing'. 
%           'mu' - a 1x2 array specifing initial peak calls
%           'sigma' - a 1x2 array specifing initial varaiance within each
%           peak population
%           'mixing' - a scalar specifying the proportion of data beloning
%           to the second peak, i.e. params.mu(2)
%   example: 
%   sig = [ randn(100,1)*.5 + 5  ; randn(80,1)*.5 + 11]; 
%   [peaks,proportions] = fitmixture(sig); 
%
% Author: Brian Geier, Broad 2010

if length(sig) < 30
    if length(sig) < 5
        muVals = 0;
        mixing = NaN;
        params = NaN; 
        iter = NaN;
    else
        muVals = median(sig); 
        mixing = NaN; 
        params = NaN; 
        iter = NaN; 
    end
    return
end

if length(unique(sig)) < 15
    muVals = median(sig); 
    mixing = 0; 
    params = NaN; 
    iter = NaN; 
    return
end


if nargin == 3
    if length(intersect(fieldnames(params),{'mu'; 'sigma' ; 'mixing'})) ~= 3
        error('Check params structure')
    end
    muVals_old = params.mu; 
    sigmaVals_old = params.sigma;
    mixing_old = params.mixing; 
     
elseif nargin == 2
    muVals_old(1) = quantile(sig,.75); 
    muVals_old(2) = quantile(sig,.25);
    sigmaVals_old = [0.75,0.75] ; 
    mixing_old = 0.5; 
    
else
    method = 'direct'; 
    muVals_old(1) = quantile(sig,.75); 
    muVals_old(2) = quantile(sig,.25);
    sigmaVals_old = [0.75,0.75] ; 
    mixing_old = 0.5; 
end

sig = sig(:);


switch method
    case 'direct'
        winner = 0.01;  
        maxIter = 1000; 
        tol = 1; 
        iter = 1;
        

        while iter <= maxIter && tol > winner
            % Expectation Step
            responsibility = (mixing_old*normpdf(sig,muVals_old(2),sigmaVals_old(2)))./...
                ( (1-mixing_old)*normpdf(sig,muVals_old(1),sigmaVals_old(1)) + ...
                mixing_old*normpdf(sig,muVals_old(2),sigmaVals_old(2))); 
            if sum(responsibility) == 0 || sum(1-responsibility) == 0
                break
            end
            responsibility = responsibility(:) ;
            % Maximization Step
            muVals(1) = sum( (1-responsibility).*sig)/sum(1-responsibility); 
            muVals(2) = sum( responsibility.*sig)/sum(responsibility); 
            sigmaVals(1) = sum( (1-responsibility).*((sig-muVals(1)).^2))...
                /sum(1-responsibility);
            sigmaVals(2) = sum( responsibility.*((sig-muVals(2)).^2))...
                /sum(responsibility);
            if any(sigmaVals == 0)
                break
            end
            mixing = sum(responsibility)/length(sig); 
            update = [muVals_old(:) - muVals(:) ; sigmaVals_old(:) - sigmaVals(:) ];
            muVals_old = muVals;
            sigmaVals_old = sqrt(sigmaVals);
            mixing_old = mixing;
            tol = abs(sum(update(:))); 
            iter = iter + 1; 
        end

        muVals_old = [median(sig(1-responsibility > .75)),...
            median(sig(responsibility > .75))]; 
        params.mu = muVals_old; 
        params.sigma = sigmaVals_old;
        params.mixing = mixing_old; 
        
        muVals = muVals_old; 
        mixing = [1-mixing_old mixing_old];
        if all(isnan(muVals))
            muVals = median(sig); 
            return
        elseif any(isnan(muVals))
            muVals(isnan(muVals)) = muVals(~isnan(muVals)); 
            return
        end
        
            
        if any(mixing <= 0.15) 
            if abs(diff(muVals)) < 1
                return
            end
            
            if mixing(2) <= 0.15
                drop = responsibility > 0.75 ;
            else
                drop = (1-responsibility) > 0.75 ; 
            end
            if sum(~drop) > 50
                [muVals,mixing,params] = fitmixture(sig(~drop));%,method,params);
            end
        end
        if numel(muVals) == 1
            muVals = repmat(muVals,[2,1]);
        end

    case 'gibbs'
        % Gibbs sampling for mixtures
        [muVals,mixing] = gibbsfit(sig); 
        
    otherwise
        error('Unsupported')
end
