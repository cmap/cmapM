function [s, varargout] = sorton(X, KEY, DIM, MODE)
% SORTON Sort array on multiple keys
% SORTON(X)
% SORTON(X, KEY)
% SORT(X, KEY, DIM)
% SORT(X, KEY, DIM, MODE)
% NOTE: Currently works for 2d arrays only
% Example:
% x=[4, 2;  3, 7;  3, 1;  5, 6]
% [s,ii]=sorton(x,[1,2],1,{'ascend','descend'})
%

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

nin=nargin;
nargchk(2,4,nin);
nout = max(nargout,1)-1;

if ~exist('KEY','var')    
   KEY=1;
else
    
end

if ~exist('DIM','var')    
   DIM=1;
end

if ~exist('MODE','var')
    MODE = 'ascend';  
end

if isequal(DIM,2)
    X = X';
end

ord = (1:size(X, 1))';
nkey = length(KEY);

for ii=nkey:-1:1
    
    if iscell(MODE)
        thisMODE = lower(MODE{ii});
    else
        thisMODE = lower(MODE);
    end
    if iscell(X)
        if isnumeric_type(X{1, KEY(ii)})
            [~, idx] = sort(cell2mat(X(ord, KEY(ii))), 1, thisMODE);
        else
            [~, idx] = sort(X(ord, KEY(ii)));
            if isequal(thisMODE, 'descend')
                idx = idx(end:-1:1);
            end
        end
    else
        [~, idx] = sort(X(ord, KEY(ii)), 1, thisMODE);
    end
    ord = ord(idx);
%     fprintf('k=%d dir=%s\n', KEY(ii), thisMODE);
%     disp(X(ord,:))
end

if isequal(DIM,1)
    s = X(ord,:);
else
    s = X(ord,:)';
end
for ii=1:nout
    varargout(ii) = {ord};
end
