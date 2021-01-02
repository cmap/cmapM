function [net, node_coords, D] = ps_net(varargin)
%Implementation of the Popularity vs Similarity Model for growing
%networks (Papadopoulos et al., Nature, 2012). In this version of the
%model, a new network t is added to the network with radial coordinate
%ln(t). This node connects to m existing nodes with probability p(d(s, t))
%= 1 / (1 + exp((d(s, t) - log(t))/T)). 
%To simulate popularity fading, the radial coordinate of each node moves
%away from the Poincare disc centre as rs = beta*rs + (1-beta)*rt where 
%rs = ln(s) and rt = ln(t).
%
%This implementation is based on the model published in:
%
%   Papadopoulos,F. et al. (2012) Popularity versus similarity in growing 
%   networks. Nature, 489, 537-540.
%
%INPUT
%   N -> Number of nodes in the final network (default = 1000).
%   m -> Parameter that controls the resulting avg. node degree in the
%        network 2m (default = 3).
%   gamma -> Parameter controlling the node degree distribution power law 
%            scaling exponent gamma = 1 + 1/beta (default = 2.5).
%   T -> Network temperature that allows clustering control (default = 0).
%   plot -> Given the geometric nature of H2-model networks, this functions
%           is able to plot their structure in the Poincaré disc if the
%           value passed to plot is 'yes' (default = 'yes').
%
%OUTPUT
%   net -> The adjacency matrix representation of the constructed 
%          Popularity-Similarity graph. If the number of parameters exceeds 
%          the maximum allowed, the returned matrix is empty.
%   node_coords -> The polar coordinates of the network nodes.
%   D -> The matrix of pairwise hyperbolic distances between network nodes.
%
%Example usage (note the parameter names are not sensitive to case):
%
%   my_network = ps_net();
%   my_network = ps_net('N', 100, 'plot', 'no');
%   my_network = ps_net('m', 10, 'n', 500)
%   my_network = ps_net('n', 500, 'Gamma', 2.8, 't', 0.25);
%
% Copyright (C) Gregorio Alanis-Lobato, 2014

%% Input parsing and validation
if nargin <= 10
    ip = inputParser;

    %Defaults
    N = 1000;
    m = 3;
    gamma = 2.5;
    T = 0;
    plot = 'yes';

    addParamValue(ip, 'N', N, @(x) isnumeric(x) && isscalar(x));
    addParamValue(ip, 'm', m, @(x) isnumeric(x) && isscalar(x) && (x > 0 && x < N));
    addParamValue(ip, 'gamma', gamma, @(x) isnumeric(x) && isscalar(x) && x > 2);
    addParamValue(ip, 'T', T, @(x) isnumeric(x) && isscalar(x) && (x >= 0 && x <= 1));
    addParamValue(ip, 'plot', plot, @(x) strcmp(x, 'yes') || strcmp(x, 'no'));
    
    parse(ip, varargin{:});

    %Validated parameter values
    N = ip.Results.N;
    m = ip.Results.m;
    gamma = ip.Results.gamma;
    T = ip.Results.T;
    plot = ip.Results.plot;
else
    fprintf('Maximum number of paremeters exceeded. ');
    fprintf('This function only accepts the following parameters:\n');
    fprintf('\tN (optional, default = 1000)\n');
    fprintf('\tm (optional, default = 3)\n');
    fprintf('\tgamma (optional, default = 2.5)\n');
    fprintf('\tT (optional, default = 0)\n');
    fprintf('\tplot (optional, default = ''yes'')\n');
    net = [];
    return;
end

%% Network construction
net = zeros(N);
node_coords = zeros(N, 2);

%Determine the value of beta
beta = 1 / (gamma - 1);

%Dummy variable
m_count = 0;

for t = 1:N
    
    %Move all nodes to their new radial coordinates to simulate popularity fading
    node_coords(1:(t-1), 1) = beta .* log(1:(t-1))' + (1-beta)*log(t);
    
    %Radial coordinate of the new node
    node_coords(t, 1) = log(t);
    %Angular coordinate of the new node
    node_coords(t, 2) = rand(1, 1) * (2 * pi);
    
    %Determine the current radius of the Hyperbolic Disc 
    if T == 0
        %(SI, Eq. 10)
        Rt = log(t) - log((2*(1 - exp(-(1 - beta)*log(t))))/(pi*m*(1 - beta)));
    else
        %(SI, Eq. 26)
        Rt = log(t) - log((2*T*(1 - exp(-(1 - beta)*log(t))))/(sin(T*pi)*m*(1 - beta)));
    end
    
    %Hyperbolic distance of the new node to all existing nodes
    d = pdist2(node_coords(t, :), node_coords(1:(t-1), :), @hyperbolic_dist);
    
    if T > 0 && t > 1
        %Compute the probability that the new node t connects to all
        %existing nodes
        p = 1 ./ (1 + exp((d - Rt)./(2*T)));
        while m_count < m
           %Choose one of the existing nodes at random
           rnd_node = randi(t - 1, 1);
           
           %Check if there is already a connection to the chosen node
           if net(t, rnd_node) == 0
               %If node t and the chosen one are not connected, connect
               %them with probability p
               if rand(1, 1) < p(rnd_node)
                   net(t, rnd_node) = 1;
                   m_count = m_count + 1;
               end
           end
           %If the number of existing nodes is less than m, stop the loop
           if m > (t - 1) && m_count == (t - 1)
               m_count = m;
           end
        end       
        m_count = 0;
    else
        %If T is 0 connect to the m hyperbolically closest nodes
        [~, idx] = sort(d);
        if numel(idx) < m
            net(t, idx) = 1;
        else
            net(t, idx(1:m)) = 1;
        end
    end
end

net = max(net, net');
D = pdist2(node_coords, node_coords, @hyperbolic_dist);
D(logical(eye(N))) = 0;

if strcmp(plot, 'yes')
    x = node_coords(:, 1) .* cos(node_coords(:, 2));
    y = node_coords(:, 1) .* sin(node_coords(:, 2));
    gplot(net, [x, y], 'k');
    hold on
    scatter(x, y, 20, node_coords(:, 2), 'filled');
end