function p0 = padjust(p, varargin)
% function (p, method = p.adjust.methods, n = length(p)) 
% {
%     method <- match.arg(method)
%     if (method == "fdr") 
%         method <- "BH"
%     p0 <- p
%     if (all(nna <- !is.na(p))) 
%         nna <- TRUE
%     p <- as.vector(p[nna])
%     stopifnot(n >= length(p))
%     if (n <= 1) 
%         return(p0)
%     if (n == 2 && method == "hommel") 
%         method <- "hochberg"
%     p0[nna] <- switch(method, bonferroni = pmin(1, n * p), holm = {
%         i <- 1L:n
%         o <- order(p)
%         ro <- order(o)
%         pmin(1, cummax((n - i + 1) * p[o]))[ro]
%     }, hommel = {
%         i <- 1L:n
%         o <- order(p)
%         p <- p[o]
%         ro <- order(o)
%         q <- pa <- rep.int(min(n * p/(1L:n)), n)
%         for (j in (n - 1):2) {
%             q1 <- min(j * p[(n - j + 2):n]/(2:j))
%             q[1L:(n - j + 1)] <- pmin(j * p[1L:(n - j + 1)], 
%                 q1)
%             q[(n - j + 2):n] <- q[n - j + 1]
%             pa <- pmax(pa, q)
%         }
%         pmax(pa, p)[ro]
%     }, hochberg = {
%         i <- n:1
%         o <- order(p, decreasing = TRUE)
%         ro <- order(o)
%         pmin(1, cummin((n - i + 1) * p[o]))[ro]
%     }, BH = {
%         i <- n:1
%         o <- order(p, decreasing = TRUE)
%         ro <- order(o)
%         pmin(1, cummin(n/i * p[o]))[ro]
%     }, BY = {
%         i <- n:1
%         o <- order(p, decreasing = TRUE)
%         ro <- order(o)
%         q <- sum(1/(1L:n))
%         pmin(1, cummin(q * n/i * p[o]))[ro]
%     }, none = p)
%     p0
% }

pnames = {'method'};
dflts = {'BH'};

arg = parse_args(pnames, dflts, varargin{:});
n=length(p);
p0 = p(:);
nna = ~isnan(p0);
p = p0(nna);

switch(upper(arg.method))
    % Benjamini & Hochberg (1995)
    case {'BH', 'FDR'}
        ii=(n:-1:1)';
        o = rankorder(p, 'direc', 'descend','fixties',false);
        ro = rankorder(o);
        minp = min(1, cummin(n./ii.*p(o)));
        p0(nna) = minp(ro);        
    otherwise
        error('Unknown method: %s', arg.method);
end

end

function [w, iw] = cummin(x)
w = zeros (size (x));
iw = w;
for ii = 1:length (x)
     [w(ii), iw(ii)] = min (x(1:ii));
end
end
