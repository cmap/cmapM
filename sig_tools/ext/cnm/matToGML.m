function matToGML(graph, varargin)
%Writes a GML file using the information given in the N-element cell array
%'nodes' (network nodes and properties) and the edges stored in the
%adjacency matrix 'graph' that represents an undirected, possibly weighted 
%graph. The names of the node properties are stored in the string array
%'attrNames'.
%
%INPUT
%   graph -> The adjacency matrix representation of a graph. It has to be a
%            NxN matrix where N is the number of nodes in the graph. This
%            parameter is required.
%   nodes -> An (Nxnumel(attrNames)) cell array with the values for the
%            properties of each of the network nodes (default = empty).
%   attrNames -> A string vector with the name of the node attributes. This
%                parameter is mandatory is 'nodes' is non-empty (default = 
%                empty).
%   fileName -> A string specifying the name of the GML file to be written
%               (default = 'myNet').
%
%OUTPUT
%   No output variables. This functions produces a GML file named
%   'fileName'.
%
%Example usage (note the parameter names are not sensitive to case):
%
%   matToGML(graph);
%   matToGML(graph, 'nodes', nodeProperties, 'attrNames', {'name', 'sex', 'age'});
%   matToGML(graph, 'fileName', 'h2_network')
%
% Copyright (C) Gregorio Alanis-Lobato, 2014

%% Input parsing and validation
if nargin <= 7
    ip = inputParser;

    %Defaults
    nodes = [];
    attrNames = [];
    fileName = 'myNet';

    %Function handle to make sure the matrix is symmetric
    issymmetric = @(x) all(all(x == x.'));

    addRequired(ip, 'graph', @(x) isnumeric(x) && issymmetric(x));
    addParamValue(ip, 'nodes', nodes, @iscell);
    addParamValue(ip, 'attrNames', attrNames, @(x) iscell(x) && isvector(x) && iscellstr(x));
    addParamValue(ip, 'fileName', fileName, @(x) ischar(x));

    parse(ip, graph, varargin{:});

    %Validated parameter values
    graph = ip.Results.graph;
    nodes = ip.Results.nodes;
    attrNames = ip.Results.attrNames;
    fileName = ip.Results.fileName;
    
    %Make sure that if 'nodes' is non-empty, it has the correct size and
    %'attrNames' too
    if ~isempty(nodes)
        if size(nodes, 1) ~= size(graph, 1)
            fprintf('Not enough node values for the network provided. \n');
            return;
        else
            if isempty(attrNames)
                fprintf('When ''nodes'' is provided, ''attrNames'' is mandatory.\n');
                return;
            elseif size(nodes, 2) ~= numel(attrNames)
                fprintf('Not enough node values for the list of attribute names provided.\n');
                return;
            end
        end
    elseif isempty(nodes) && ~isempty(attrNames)
        fprintf('''attrNames'' requires that ''nodes'' is non-empty.\n');
        return;
    end
else
    fprintf('Maximum number of paremeters exceeded. ');
    fprintf('This function only accepts the following parameters:\n');
    fprintf('\tgraph (required)\n');
    fprintf('\tnodes (optional, default = [])\n');
    fprintf('\tattrNames (optional, default = [])\n');
    fprintf('\tfileName (optional, default = ''myNet'')\n');
    return;
end

%% GML file generation

N = size(graph, 1); %Number of nodes
if ~isempty(attrNames)
    attributes = numel(attrNames); %Number of node attributes (future version)
end

%List of edges
graph = max(graph, graph');
[nodeA, nodeB, weight] = find(triu(graph, 1));
edges = [nodeA, nodeB, weight];
E = size(edges, 1); %Number of edges

fid = fopen([fileName, '.gml'], 'w');

%Creator and opening
fprintf(fid, 'Creator "MAT-to-GML by CNM Toolbox"\n');
fprintf(fid, 'graph\n');
fprintf(fid, '[');
fprintf(fid, '\t directed 0\n');

%Writing node information
for i = 1:N
    fprintf(fid, '\t node\n');
    fprintf(fid, '\t [\n');
    fprintf(fid, '\t\t id %u\n', round(i));
    if ~isempty(nodes)
        for j = 1:attributes
            if isa(nodes{i, j}, 'numeric')
                fprintf(fid, '\t\t %s %d\n', attrNames{j}, nodes{i, j});
            elseif isa(nodes{i, j}, 'char')
                fprintf(fid, '\t\t %s %s\n', attrNames{j}, nodes{i, j});
            end
        end
    end
    fprintf(fid, '\t ]\n');
end

%Writing edge information
for i = 1:E
    fprintf(fid, '\t edge\n');
    fprintf(fid, '\t [\n');
    fprintf(fid, '\t\t source %u\n', edges(i, 1));
    fprintf(fid, '\t\t target %u\n', edges(i, 2));
    fprintf(fid, '\t\t value %f\n', edges(i, 3));
    fprintf(fid, '\t ]\n');
end

%End of GML file
fprintf(fid, ']');
fclose(fid);