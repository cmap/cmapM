function plotNodeDegreeDistrib(graph, varargin)
%Plots the histrogram of the node-degree distribution for an undirected, 
%unweighted network 'graph' with degree-counts based on the number of 
%specified 'bins'. The degree distribution can be plotted on the log-log 
%scale or the normal scale, depending on the user's choice (via parameter 
%'plotType').
%
%INPUT
%   graph -> The adjacency matrix representation of a graph. It has to be a
%            NxN matrix where N is the number of nodes in the graph. This
%            parameter is required.
%   bins -> Specifies the number of bins into which the node degrees are 
%           sorted (default = 50). 
%   plotType -> It takes strings 'loglog' or 'normal' and specifies
%                whether the node degree distribution is plotted in the
%                log-log scale or the normal scale respectively (default =
%                'loglog').
%
%OUTPUT
%   No output variables. This functions produces a plot only.
%
%Example usage (note the parameter names are not sensitive to case):
%
%   plotNodeDegreeDistrib(my_network);
%   plotNodeDegreeDistrib(my_network, 'bins', 70);
%   plotNodeDegreeDistrib(my_network, 'plotType', 'normal');
%   plotNodeDegreeDistrib(my_network, 'Bins', 75, 'plotType', 'normal');
%   plotNodeDegreeDistrib(my_network, 'PlotType', 'loglog', 'bins', 50, );
%
% Copyright (C) Gregorio Alanis-Lobato, 2014

%% Input parsing and validation
if nargin <= 5
    ip = inputParser;

    %Defaults
    bins = 50;
    plotType = 'loglog';

    %Function handle to make sure the matrix is symmetric
    issymmetric = @(x) all(all(x == x.'));

    addRequired(ip, 'graph', @(x) isnumeric(x) && issymmetric(x));
    addParamValue(ip, 'bins', bins, @(x) isnumeric(x) && isscalar(x));
    addParamValue(ip, 'plotType', plotType, @(x) strcmp(x, 'loglog') || strcmp(x, 'normal'));

    parse(ip, graph, varargin{:});

    %Validated parameter values
    graph = ip.Results.graph;
    bins = ip.Results.bins;
    plotType = ip.Results.plotType;
else
    fprintf('Maximum number of paremeters exceeded. ');
    fprintf('This function only accepts the following parameters:\n');
    fprintf('\tgraph (required)\n');
    fprintf('\tbins (optional, default = 50)\n');
    fprintf('\tplotType (optional, default = ''loglog'')\n');
    return;
end

%% Node degree distribution plotting

%Make sure that the graph unweighted!!!
graph(graph > 0) = 1; 

deg = sum(graph, 2); %Determine node degrees

[counts, x] = hist(deg, bins); %Compute the density of degree intervals

%Plot the node-degree distribution in the scale chosen by the user
if strcmp(plotType, 'loglog')
    loglog(x, counts./sum(counts), '.');
    xlabel('Node degree   k');
    ylabel('P(k)');
elseif strcmp(plotType, 'normal')
    scatter(x, counts./sum(counts), '.');
    xlabel('Node degree   k');
    ylabel('P(k)');
end