function fixed = rm_filedim(s)
% Remove dimensions from filename
%  T = RM_FILEDIM(S)
%   file_n123 -> file
%   file_n1x10 -> file

fixed = regexprep(s, '_n[0-9]*$|_n[0-9]*x[0-9]*$','');

end