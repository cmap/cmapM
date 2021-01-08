% FOLD2AMP Convert fold change to differential amplitude measure 
%   A = FOLD2AMP(F) returns the amplitude corresponding to the fold change
%   in F. F can be a matrix.
%   
%   CMAP definition of amplitude : A measure of the extent of differential
%   expression of a given probe set. Amplitude a is defined as follows: 
%
%   a = (t - c) / [(t + c)/2]
%
%   Where t is the scaled and thresholded average difference value for the
%   treatment and c is the thresholded average difference value for the
%   control. Thus, a=0 indicates no differential expression, a>0 indicates
%   increased expression upon treatment, and a<0 indicates decreased
%   expression upon treatment. For example, an amplitude of 0.67 represents
%   a two-fold induction. 

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT


function a = fold2amp(fc)

a = 2*(fc-1) ./ (1+fc); 
