function vn = validateVar(n, rep)
% VALIDATEVAR check for valid matlab variable name.
%   VN = VALIDATEVAR(N) Checks if N is a valid matlab variable and removes
%   invalid chars from the name.
%
%   VN = VALIDATEVAR(N, REP) replaces invalid characters with REP instead of
%   removing them.

if (~exist('rep', 'var'))
    rep='';
end

if iscell(n)
    numv = length(n);
else
    n={n};
    numv=1;
end

vn = cell(numv,1);

for ii=1:numv
    if ~isempty(n{ii})
        %first char
        v1 = regexprep(n{ii}(1),...
            ['(%|&|{|}|\s|+|-|!|@|#|\$|\^|*|\(|\)|=|\[|\]|',...
            '\\|;|:|~|`|,|\.|<|>|?|/|_|"|\|\x22|\x27|\x7c)'],...
            rep);
        % first char cannot be a number
        v1 = regexprep(v1, sprintf('(^[0-9%s])', rep),'n$1');
        
        vrest = regexprep(n{ii}(2:end),...
            ['(%|&|{|}|\s|+|-|!|@|#|\$|\^|*|\(|\)|=|\[|\]|',...
            '\\|;|:|~|`|,|\.|<|>|?|/|"|\|\x22|\x27|\x7c)'],...
            rep);
        % remove contiguous replacements
        vn{ii} = regexprep(strsqueeze([v1,vrest], rep),...
            [rep,'$'],'');
    else
        vn{ii} = sprintf('VAR_%d',ii);
    end
end
end