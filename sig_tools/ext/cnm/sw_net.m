function [net, cc, sp] = sw_net(varargin)
%
%This implementation is based on the model published in:
%
%   Watts,D.J. and Strogatz,S.H. (1998) Collective dynamics of 
%   "small-world" networks. Nature, 393, 440-442.
%
%INPUT
%   N -> The number of network nodes (default = 1000).
%   k -> The number of nearest neighbours to which each node is connected
%        in the original regular lattice (default = 5).
%   p -> The propability of rewiring. It can also be a range between [0,1]
%        (default = 0.25).
%   plot -> Only works when p is a range and it can be 'yes' or 'no' to
%           indicate whether to plot the different values of clustering 
%           coefficient and characteristic path length taken for the 
%           provided range (default = 'yes').
%OUTPUT
%   net -> The adjacency matrix representation of the constructed 
%          small-world network. If the number of parameters exceeds the
%          maximum allowed, the returned matrix is empty. If p is a range,
%          it is a 3D matrix of size (NxNxnumel(p)).
%   cc -> The clustering coefficient(s) of the generated network(s).
%   sp -> The average shortest path(s) of the generated network(s).
%
%Example usage (note the parameter names are not sensitive to case):
%
%   [my_network, cc, sp] = sw_net();
%   [my_network, cc] = er_net('N', 100);
%   [my_network, ~, sp] = er_net('p', 0.15)
%   [~, cc, sp] = er_net('n', 500, 'P', 0:0.01:1, 'plot', 'no');
%
% Copyright (C) Gregorio Alanis-Lobato, 2014

%% Input parsing and validation
if nargin <= 8
    ip = inputParser;

    %Defaults
    N = 1000;
    k = 5;
    p = 0.25;
    plot = 'yes';

    addParamValue(ip, 'N', N, @(x) isnumeric(x) && isscalar(x));
    addParamValue(ip, 'k', k, @(x) isnumeric(x) && isscalar(x) && (x > 0 && x < N));
    addParamValue(ip, 'p', p, @(x) isnumeric(x) && isvector(x) && (all(x >=0) && all(x <= 1)));
    addParamValue(ip, 'plot', plot, @(x) strcmp(x, 'yes') || strcmp(x, 'no'));
    
    parse(ip, varargin{:});

    %Validated parameter values
    N = ip.Results.N;
    k = ip.Results.k;
    p = ip.Results.p;
    plot = ip.Results.plot;
    
    %Make sure k is less than N
    if k >= N
        fprintf('Parameter k failed validation k < N.\n\n');
        net = [];
        cc = [];
        sp = [];
        return;
    end
else
    fprintf('Maximum number of paremeters exceeded. ');
    fprintf('This function only accepts the following parameters:\n');
    fprintf('\tN (optional, default = 1000)\n');
    fprintf('\tp (optional, default = 0.25)\n');
    fprintf('\tk (optional, default = 5)\n');
    fprintf('\tplot (optional, default = 5)\n');
    net = [];
    return;
end

%% Construction of the small-world network.
if numel(p) > 1
    net = zeros(N, N, numel(p));
else
    net = zeros(N);
end

%N nodes are distributed uniformly around a ring
nodes = (0:(2*pi/N):(2*pi - (2*pi/N)))';
%Obtain the pairwise angular distances between nodes to detect the k
%nearest neighbours of each one
theta_ij = pdist2(nodes, nodes, @angular_dist);
%Make the diagonal Inf so that the lattice construction works
theta_ij(logical(eye(N))) = Inf; 

%Construct the initial regular lattice
lattice = zeros(N);
for i = 1:N
    [~, idx] = sort(theta_ij(i, :)); %Sort distances of i to its neighbours
    lattice(i, idx(1:k)) = 1; %Connect i to its k nearest neighbours
end

%Make sure the lattice is undirected and symmetric
lattice = max(lattice, lattice');
%Obtain the edge list of the lattice
[a, b] = find(triu(lattice, 1));
edges = [a, b]; clear a b

for i = 1:numel(p)
    net(:, :, i) = lattice;
    %Visit each edge and rewire with probability p
    for j = 1:size(edges, 1)
        if rand(1, 1) < p(i)
            pop = 1:N;
            %Remove the edge ends from the node population to avoid self
            %and multiple connections
            pop(edges(j, 1)) = NaN;
            pop(edges(j, 2)) = NaN;
            pop(isnan(pop)) = [];
            %Sample without replacement from the available node population
            new_node = randsample(pop, 1); 
            %Rewire
            if net(edges(j, 1), new_node, i) ~= 1
                net(edges(j, 1), edges(j, 2), i) = 0;
                net(edges(j, 2), edges(j, 1), i) = 0;
                net(edges(j, 1), new_node, i) = 1;
                net(new_node, edges(j, 1), i) = 1;
            end
        end
    end
end

%Compute the average clustering coefficient and characteristic path lentgh
%of the constructed networks
cc = zeros(numel(p), 1);
sp = cc;

for i = 1:numel(p)
    cc(i) = avgClusteringCoefficient(net(:, :, i));
    sp(i) = characteristicPathLength(net(:, :, i));
end

%Plot if required by the user and if numel(p) > 1
if numel(p) > 1 && strcmp(plot, 'yes')
    cc_0 = avgClusteringCoefficient(lattice);
    sp_0 = characteristicPathLength(lattice);
    semilogx(p, cc ./ cc_0, '.r');
    hold on
    semilogx(p, sp ./ sp_0, '.b');
    xlabel('p')
    legend('C(p)/C(0)', 'L(p)/L(0)')
end
    





