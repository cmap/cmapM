function name = insertslash(name)
% INSERTSLASH Insert slash at each _ 
%   name = INSERTSLASH(name) will replace each _ by \_ , Tex source
%   compiling will throw an error in the event of _ 
% example: 
%   insertslash('this_is')
% Author: Brian Geier

ix = find(name == '_'); 
for i = 1 : length(ix)
    left = name(1:ix(1)-1); 
    right = name(ix(1)+1:end); 
    name = horzcat(left,'\_',right); 
    ix = find(name == '_'); 
    ix(1:i) = [];
end


end