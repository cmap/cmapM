function [cpl, cpl_std] = characteristicPathLength(graph)
%Computes the Characteristic Path Length (avg. shortest-path) for the 
%undirected, unweighted graph input as adjacency matrix 'graph' and returns
%it in variable 'cpl'. It also returns the standard deviation of the
%shortest-path lengths in the graph.
%
%INPUT
%   graph -> The adjacency matrix representation of a graph. It has to be a
%            NxN matrix where N is the number of nodes in the graph. This
%            parameter is required.
%
%OUTPUT
%   cpl -> Characteristic path length of the input graph.
%   cpl_std -> Standard deviation of the shortest-path lengths in the graph.
%
%Example usage:
%
%   [cpl, cpl_std] = characteristicPathLength(my_net);
%   cpl = characteristicPathLength(my_net);
%   [~, cpl_std] = characteristicPathLength(my_net);
%
% Copyright (C) Gregorio Alanis-Lobato, 2014

%% Input parsing and validation
ip = inputParser;

%Function handle to make sure the matrix is symmetric
issymmetric = @(x) all(all(x == x.'));

addRequired(ip, 'graph', @(x) isnumeric(x) && issymmetric(x));

parse(ip, graph);

%Validated parameter values
graph = ip.Results.graph;

%% Characteristic path length computation

%Make sure the graph unweighted!!!
graph(graph ~= 0) = 1;

sp = graphallshortestpaths(sparse(graph), 'directed', 'false');
sp = squareform(sp, 'tovector');

%Get rid of SP lengths between disconnected components
sp(isinf(sp)) = [];
cpl = mean(sp);
cpl_std = std(sp);
