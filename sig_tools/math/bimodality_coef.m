function [bc, m3, m4] = bimodality_coef(data, correct_bias)
% BIMODALITY_COEF Bimodality Coefficient
%   BC = BIMODALITY_COEF(X) Computes the bimodality coefficient of each
%   column of X defined as:
%   bc = (m3.^2+1)./(m4+3*((nr-1).^2/((nr-2)*(nr-3))))
%   BC = BIMODALITY_COEF(X, CORRECT_BIAS) 
if ~isvarexist('correct_bias_flag')
    correct_bias = true;
else
    correct_bias = abs(correct_bias)>0;
end

% for both skewness and kurtosis 0 = bias correction, 1 = no correction
bcflag = ~correct_bias;

[nr, nc] = size(data);
% skewness
m3 = skewness(data, bcflag, 1);
% excess kurtosis
m4 = kurtosis(data, bcflag, 1) - 3;
% bimodality coef
bc = (m3.^2+1)./(m4+3*((nr-1).^2/((nr-2)*(nr-3))));
 
end