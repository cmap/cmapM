function net = ba_net(varargin)
%Generates a network with N nodes and avg. node degree 2m following the
%Barabasi-Albert model, starting from a network with m0 nodes.
%
%This implementation is based on the model published in:
%
%   Barabási,A.-L. and Albert,R. (1999) Emergence of Scaling in Random 
%   Networks. Science, 286, 509-512.
%
%INPUT
%   N -> Number of nodes in the graph (default = 1000).
%   m0 -> Initial number of nodes in the network (default = 5). This
%         parameters has to be > 0.
%   m -> Number of nodes with which a new node in the network connects to 
%        This parameter has to be <= to m0 (default = 3).
%
%OUPUT
%   net -> The adjacency matrix representation of the constructed 
%          Barbási-Albert network. If the number of parameters exceeds the
%          maximum allowed, the returned matrix is empty.
%
%Example usage (note the parameter names are not sensitive to case):
%
%   my_network = ba_net();
%   my_network = ba_net('N', 100);
%   my_network = ba_net('m0', 10);
%   my_network = ba_net('m', 2);
%   my_network = er_net('n', 500, 'M0', 25, 'M', 10);
%
% Copyright (C) Gregorio Alanis-Lobato, 2014


%% Input parsing and validation
if nargin <= 6
    ip = inputParser;

    %Defaults
    N = 1000;
    m0 = 5;
    m = 3;

    addParamValue(ip, 'N', N, @(x) isnumeric(x) && isscalar(x));
    addParamValue(ip, 'm0', m0, @(x) isnumeric(x) && isscalar(x) && (x > 0 && x < N));
    addParamValue(ip, 'm', m, @(x) isnumeric(x) && isscalar(x) && x <= m0);
        
    parse(ip, varargin{:});
    
    %Validated parameter values
    N = ip.Results.N;
    m0 = ip.Results.m0;
    m = ip.Results.m;
    
    %Make sure that m is less than or equal to m0
    if m > m0
        fprintf('Parameter m failed validation m <= m0.\n\n');
        net = [];
        return;
    end
else
    fprintf('Maximum number of paremeters exceeded. ');
    fprintf('This function only accepts the following parameters:\n');
    fprintf('\tN (optional, default = 1000)\n');
    fprintf('\tm0 (optional, default = 5)\n');
    fprintf('\tm (optional, default = 3)\n');
    net = [];
    return;
end

%% Barabási-Albert network construction

net = zeros(N);

%Nodes 1 to m0 form a clique
net(1:m0, 1:m0) = 1;
net(logical(eye(N))) = 0;

for i = (m0+1):N
    %Add a new node to the network and connect to m existing nodes if they
    %indeed exist
    
    if i <= m
        net(i, 1:i) = 1; %If m is larger than the number of nodes in the system, connect to all of them
        net(i, i) = 0; %Self-connections not allowed
    else
        k = sum(net(1:(i-1), 1:(i-1)), 2); %Degree of the existing nodes
        k_total = sum(k);
        p = k./k_total; %Attraction probability of each node in the network
        
        r = rand(i-1, 1);
        
        if nnz(r < p) < m
            %Connect to the m minimum p
            [~, idx] = sort(r);
            net(i, idx(1:m)) = 1;
        else
            %Find with whom to connect to
            net(i, r < p) = 1;
        end     
        
    end
end

%Make sure the network is symmetric and has zero-diagonal
net = max(net, net');
net(logical(eye(N))) = 0;
    