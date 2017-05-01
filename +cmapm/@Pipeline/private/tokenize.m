% TOKENIZE split a string based on a specified delimiter
%   [tok,ntok] = tokenize(s,t,trim)

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

function [tok,ntok] = tokenize(s,t,trim)

% ntok = cellfun(@length,strfind(s,t))+1;
% tok = cell(ntok,1);
% 
% for ii=1:ntok
%     [tok(ii),s] = strtok(s,t);    
% end

% ctr=1;
% while ~isempty(r)    
%     ctr=ctr+1;
%    [tok{ctr},r] = strtok(r,t);
% end

if (~exist('trim','var'))
    trim=false;
end

if iscell(s)
    n=length(s);
    tok=cell(n,1);
    ntok=zeros(n,1);
    for ii=1:n
        [tok{ii}, ntok(ii)] = tokenize(s{ii},t,trim);
    end
else
    
    % find tokens
    toks = strfind(s,t);
    toklen=length(t);
    st=[1,toks+toklen];
    stp = [toks-1, length(s)];
    ntok = length(toks)+1;
    
    tok = cell(ntok,1);
    
    for ii=1:ntok
        tok{ii} = s(st(ii):stp(ii));
        %     [tok(ii),s] = strtok(s,t);
    end
    
    if trim
        tok=strtrim(tok);
    end

end
