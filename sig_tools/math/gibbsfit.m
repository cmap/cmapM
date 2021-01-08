function [peaks,mixing,step] = gibbsfit(sig) 
% Error checking is performed in fitmixture.m 
% This is a subroutine to fitmixture.m
% Fits a gaussian mixture model using a gibbs sampler

warning off

if length(sig) < 50
    peaks = median(sig); 
    mixing = 0; 
    step = 0;
    return
end

if length(unique(sig)) < 15
    peaks = median(sig); 
    mixing = 0; 
    step = 0;
    return
end

% Random/Heuristic Initial
muVals_old(1) = quantile(sig,.25); 
muVals_old(2) = quantile(sig,.75);
sigmaVals_old = [0.75,0.75] ; 
mixing_old = rand*(.75)+0.25; 


% winner = 0.001; % accuracy
burns = 500; % burning period for gibb sampler
step = 1 ; 
% tol = 1;
gibbeys = randn(2,burns); 

while step <= burns %&& tol > winner
% for j = 1 : burns
    resp = (mixing_old*normpdf(sig,muVals_old(2),sigmaVals_old(2)))./...
        ( (1-mixing_old)*normpdf(sig,muVals_old(1),sigmaVals_old(1)) + ...
        mixing_old*normpdf(sig,muVals_old(2),sigmaVals_old(2))); 
    if sum(resp) == 0 || sum(1-resp) == 0
        break
    end
    
    delta = zeros(length(sig),1); 
    for i = 1 : length(delta)
        delta(i) = randsample([1,0],1,true,[resp(i),1-resp(i)]); 
    end
    if sum(delta) == 0 || sum(delta) == 1
        break
    end

    peaks = [ sum( (1-delta).*sig )./ sum( 1-delta) , ...
        sum( delta.*sig ) /sum(delta)]  ; 

    spread = [sum( (1-resp).*((sig-peaks(1)).^2))/sum(1-resp), ...
        sum( resp.*((sig-peaks(2)).^2))/sum(resp)];

    spread = [invchi(length(sig),spread(1)),invchi(length(sig),spread(2))];
    spread = sqrt(spread); 

    if any(spread == 0)
        break
    end
    muVals_old = [gibbeys(1,step).*spread(1) + peaks(1),...
        gibbeys(2,step).*spread(2) + peaks(2) ] ;  
    sigmaVals_old = spread ;
    mixing_old = sum(delta)/length(delta); 
%     update =  muVals_old(:) - peaks(:) ;
%     tol = abs(sum(update(:))); 
    step = step + 1; 
end

mixing = [1-mixing_old mixing_old]; 
peaks = muVals_old; 

if any(mixing < 0.2)
    if abs(diff(peaks)) < 1
        return
    end
    if mixing(2) < 0.2
        drop = resp > 0.75;
    else
        drop = (1-resp) > 0.75;
    end
    
    [peaks,mixing] = gibbsfit(sig(~drop)); 
end


warning on ; 
end

            
function y = invchi(df,scale)

y = (df*scale)./chi2rnd(df); 

end
