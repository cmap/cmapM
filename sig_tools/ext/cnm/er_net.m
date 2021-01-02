function net = er_net(varargin)
%Generates an Erdos-Rényi random graph of N nodes that connect with each
%other with probability p.
%
%This implementation is based on the model published in:
%
%   Erdos,P. and Rényi,A. (1960) On the evolution of random graphs. Publ. 
%   Math. Inst. Hungarian Acad. Sci., 5, 17-61.
%
%INPUT
%   N -> Number of nodes in the graph (default = 1000).
%   p -> Probability with which each pair of nodes forms an edge (default =
%        0.1).
%
%OUPUT
%   net -> The adjacency matrix representation of the constructed 
%          Erdos-Rényi graph. If the number of parameters exceeds the
%          maximum allowed, the returned matrix is empty.
%
%Example usage (note the parameter names are not sensitive to case):
%
%   my_network = er_net();
%   my_network = er_net('N', 100);
%   my_network = er_net('p', 0.25);
%   my_network = er_net('n', 500, 'P', 0.35);
%
% Copyright (C) Gregorio Alanis-Lobato, 2014

%% Input parsing and validation
if nargin <= 4
    ip = inputParser;

    %Defaults
    N = 1000;
    p = 0.1;

    addParamValue(ip, 'N', N, @(x) isnumeric(x) && isscalar(x));
    addParamValue(ip, 'p', p, @(x) isnumeric(x) && isscalar(x) && (x >=0 && x <= 1));
    
    parse(ip, varargin{:});

    %Validated parameter values
    N = ip.Results.N;
    p = ip.Results.p;
else
    fprintf('Maximum number of paremeters exceeded. ');
    fprintf('This function only accepts the following parameters:\n');
    fprintf('\tN (optional, default = 1000)\n');
    fprintf('\tp (optional, default = 0.1)\n');
    net = [];
    return;
end

%% Erdos-Rényi graph construction
net = triu(rand(N) < p, 1);
net = double(max(net, net'));

