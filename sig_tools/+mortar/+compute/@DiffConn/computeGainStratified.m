function gain = computeGainStratified(pos_score, neg_score, ps_th)
% glc parameters
gp = struct('ymax', 1,...    
            'x0', 40,...
            'k', 0.03,...
            'nu', 2);

% gp = struct('ymax', 1,...    
%             'x0', 70,...
%             'k', 0.04,...
%             'nu', 2.0);
        
% range of GLC        
ymin = richards_curve(0, gp.ymax, gp.x0, gp.k, gp.nu);
ymax = richards_curve(200, gp.ymax, gp.x0, gp.k, gp.nu);

% difference in score
abs_delta = abs(pos_score - neg_score);
% is either score significant
is_signif_score = abs(pos_score)>=ps_th | abs(neg_score)>=ps_th;

% apply shaping function
gain = clip(is_signif_score + (richards_curve(abs_delta,...
       gp.ymax, gp.x0, gp.k, gp.nu) - ymin) / (ymax - ymin), 0, 2);

end