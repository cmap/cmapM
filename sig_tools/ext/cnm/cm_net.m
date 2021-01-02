function net = cm_net(input)
%Construction of a network given a node degree sequence 'deg_seq' or the
%adjacency matrix representation of a graph 'graph' from which the degree
%sequence is extracted and respected in the construction process.
%
%This implementation is based on the model described in:
%
%   Molloy, M., & Reed, B. (1995). A critical point for random graphs with 
%   a given degree sequence. Random Structures and Algorithms, 6(2-3), 161-179.
%
%but with duplicate edges and self-loops forbidden.
%
%INPUT
%   input -> Network from which the degree sequence is to be extracted.
%            This network has to be undirected and unweighted.
%     or
%         -> The degree sequence to be respected in the generated
%            network.
%   Either of the above parameters is required.
%
%OUPUT
%   net -> The adjacency matrix representation of the network constructed 
%          with the Configuration Model. If the number of parameters 
%          exceeds the maximum allowed, the returned matrix is empty.
%
%Example usage (note the parameter names are not sensitive to case):
%
%   my_network = cm_net(my_seq);
%   my_network = er_net(my_graph);
%
% Copyright (C) Gregorio Alanis-Lobato, 2014

%% Input parsing and validation
if nargin == 0
    fprintf('This function requires one of the following two parameters:\n');
    fprintf('\tdeg_seq\n');
    fprintf('\tgraph\n');
    net = [];
    return;
elseif nargin <= 2 && nargin > 0
    ip = inputParser;

    if isvector(input)
        addRequired(ip, 'deg_seq', @isnumeric);
        parse(ip, input);
        deg_seq = ip.Results.deg_seq;
        if isrow(deg_seq)
            deg_seq = deg_seq';
        end
    elseif ismatrix(input)
        %Function handle to make sure the matrix is symmetric
        issymmetric = @(x) all(all(x == x.'));

        addRequired(ip, 'graph', @(x) isnumeric(x) && issymmetric(x));
        parse(ip, input);
        graph = ip.Results.graph;
        deg_seq = sum(graph, 2);
    else
        fprintf('This function requires one of the following two parameters:\n');
        fprintf('\tdeg_seq\n');
        fprintf('\tgraph\n');
        net = [];
        return;
    end
else
    fprintf('Maximum number of paremeters exceeded. ');
    fprintf('This function only accepts one of the following two parameters:\n');
    fprintf('\tdeg_seq\n');
    fprintf('\tgraph\n');
    net = [];
    return;
end

%% Configuration model network construction
N = numel(deg_seq);
links = sum(deg_seq) / 2;

net = zeros(N);

%Create a list of node stubs
num_stubs = sum(deg_seq);
stubs = zeros(num_stubs, 1); %List of node IDs
dum = 0;
for i = 1:N
    stubs((dum+1):(dum+deg_seq(i))) = i;
    dum = dum+deg_seq(i);
end

link_counter = 0;
unique_nodes = numel(unique(stubs));

%Generate the network with neither self interactions nor multiple edges
while link_counter < links && unique_nodes > 1 && sum(sum(net(unique(stubs), unique(stubs)))) < (unique_nodes^2 - unique_nodes)
    edge = randsample(num_stubs, 2); %Sample 2 nodes from the stub list without replacement
    if stubs(edge(1)) ~= stubs(edge(2)) && net(stubs(edge(1)), stubs(edge(2))) == 0
        net(stubs(edge(1)), stubs(edge(2))) = 1;
        net(stubs(edge(2)), stubs(edge(1))) = 1;
        link_counter = link_counter + 1;
        
        %Delete the used stubs from the stub list and update the number of
        %available stubs num_stubs. The entries of the stub list are put to NaN 
        %and then deleted to ensure the right stubs are deleted (deleting 
        %the 1st stub directly will shrink the list and make the second 
        %stub index invalid)!!! Also update the number of unique node IDs
        %in the stub list
        stubs(edge(1)) = NaN;
        stubs(edge(2)) = NaN;
        stubs(isnan(stubs)) = [];
        num_stubs = numel(stubs);
        unique_nodes = numel(unique(stubs));
    end
end
