function [acc, c] = avgClusteringCoefficient(graph)
%Computes the Average Clustering Coefficient for the undirected, unweighted
%graph input as adjacency matrix 'graph' and returns it in variable 'acc'. 
%It also returns the local clustering coefficient of each node in 'c'.
%This implementation does not take into account nodes with zero degree.
%
%The definition of clustering coefficient used in this implementation was
%taken from:
%
%   Watts,D.J. and Strogatz,S.H. (1998) Collective dynamics of 
%   "small-world" networks. Nature, 393, 440-442.
%
%INPUT
%   graph -> The adjacency matrix representation of a graph. It has to be a
%            NxN matrix where N is the number of nodes in the graph. This
%            parameter is required.
%
%OUTPUT
%   acc -> Average clustering coefficient of the input graph.
%   c -> Local clustering coefficient of each of the graph's nodes
%
%Example usage:
%
%   [acc, c] = avgClusteringCoefficient(my_net);
%   acc = avgClusteringCoefficient(my_net);
%   [~, c] = avgClusteringCoefficient(my_net);
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


%% Clustering coefficient computation

%Make sure the graph unweighted!!!
graph(graph ~= 0) = 1; 

deg = sum(graph, 2); %Determine node degrees
cn = diag(graph*triu(graph)*graph); %Number of triangles for each node

%The local clustering coefficient of each node
c = zeros(size(deg));
c(deg > 1) = 2 * cn(deg > 1) ./ (deg(deg > 1).*(deg(deg > 1) - 1)); 

%Average clustering coefficient of the graph
acc = mean(c(deg > 1)); 
