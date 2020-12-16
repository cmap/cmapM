function gain = computeGain(pos_score, neg_score)
% computeGain Compute the differential connectivity gain between two 
%   groups of connectivity scores
%
% gain = computeGain(pos_score, neg_score)

% sigmoid parameters
sp = struct('sgn', 1,...
                   'x0', 80,...
                   'k', 8,...
                   'm', 1);
% glc parameters
gp = struct('ymax', 1,...    
            'x0', 0.6,...
            'k', 4,...
            'nu', 1.5);

% range of GLC        
ymin = richards_curve(0, gp.ymax, gp.x0, gp.k, gp.nu);
ymax = richards_curve(2, gp.ymax, gp.x0, gp.k, gp.nu);

% apply weighting function to difference of connectivity scores
gain = sign(pos_score).*(richards_curve(abs(sign(pos_score).*sigmoid(abs(pos_score), sp.sgn, sp.x0, sp.k, sp.m) - ...
       sign(neg_score).*sigmoid(abs(neg_score), sp.sgn, sp.x0, sp.k, sp.m)),...
       gp.ymax, gp.x0, gp.k, gp.nu) - ymin) / (ymax - ymin);

end