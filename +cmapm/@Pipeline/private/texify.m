function out = texify(s)
% TEXIFY escapes special characters in strings.
%  O = TEXIFY(S) escapes special chracters in string S so that they
%  are printed literally by Matlabs built-in TeX interpreter.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

%deal with $s since we need them for the backslash!
out=regexprep(s,'\$','\$');
%deal with back slashes first

out=regexprep(out,'\\','$\\backslash$');
%then other special symbols
out=regexprep(out,'(&|_|{|})','\\$1');
