% AMP2FOLD Convert differential amplitude to fold change.
%   F = AMP2FOLD(A) returns the fold change corresponding to the amplitudes
%   in A. A can be a matrix. Fold change is related to amplitude as
%   follows:
%   
%   F = (2+A) / (2-A)
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


function f = amp2fold(a)

f = (2+a) ./ (2-a); 
