function [tok,ntok] = tokenize(s,t,trim)
% TOKENIZE split a string based on a specified delimiter
%   [T, N] = tokenize(S,D) divides S into tokens
%   using the characters in the string D. The result is stored
%   in a single-column cell array of strings. If S is a cell array, each
%   element is sequentially tokenized and the results are returned as a
%   cell array of size(S)
%
%   [T, N] = tokenize(S,D, ISTRIM) removed whitespace from tokens if ISTRIM
%   is true

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

if (~exist('trim','var'))
    trim=false;
end

if iscell(s)
    nel = numel(s);
    tok=cell(size(s));
    ntok=zeros(size(s));
    for ii=1:nel
        [tok{ii}, ntok(ii)] = tokenize(s{ii},t,trim);
    end
    
    if all(ntok==1)
        tok = s;
    end
elseif ischar(s)    
    tok = strsplit(s, t)';
    ntok = length(tok);
%     % find tokens
%     toks = strfind(s,t);
%     toklen=length(t);
%     st=[1,toks+toklen];
%     stp = [toks-1, length(s)];
%     ntok = length(toks)+1;
%     
%     tok = cell(ntok,1);
%     
%     for ii=1:ntok
%         tok{ii} = s(st(ii):stp(ii));
%         %     [tok(ii),s] = strtok(s,t);
%     end
    
    if trim
        tok=strtrim(tok);
    end
else
    tok = s;
    ntok = 1;
end
