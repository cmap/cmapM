function [net, node_coords, D] = h2_net(varargin)
%Generates an random graph of N nodes quasi-uniformly distrubuted in the
%hyperbolic space represented by the Poincaré disc of radius R ~ ln(N).
%
%This implementation is based on the model published in:
%
%   Krioukov,D. et al. (2010) Hyperbolic geometry of complex networks. 
%   Phys. Rev. E, 82, 036106-1-036106-18.
%
%and further described in:
%
%   Boguñá, M., Papadopoulos, F., & Krioukov, D. (2010). Sustaining the 
%   Internet with hyperbolic mapping. Nature Communications, 1:62.
%
%INPUT
%   N -> Number of nodes in the graph (default = 1000).
%   ave_deg -> Target average node degree of the network (default = 5).
%   gamma -> Target power law scaling exponent of the network's node degree
%            distribution (default = 2.5).
%   T -> Network temperature that allows for clustering tuning (default =
%        0).
%   connected -> The networks constructed by this model can have several
%                connected components. To ensure only one is generated, use
%                this function with parameter connected set to 'yes'. Note
%                that this parameter may change the values of the resulting
%                power law exponent, average node degree and clustering
%                (default = 'no').
%   plot -> Given the geometric nature of H2-model networks, this functions
%           is able to plot their structure in the Poincaré disc if the
%           value passed to plot is 'yes' (default = 'yes').
%
%OUPUT
%   net -> The adjacency matrix representation of the constructed 
%          H2-model graph. If the number of parameters exceeds the
%          maximum allowed, the returned matrix is empty.
%   node_coords -> The polar coordinates of the network nodes.
%   D -> The matrix of pairwise hyperbolic distances between network nodes.
%
%Example usage (note the parameter names are not sensitive to case):
%
%   my_network = h2_net();
%   my_network = h2_net('N', 100, 'plot', 'no');
%   my_network = h2_net('ave_deg', 10, 'Connected', 'yes')
%   my_network = h2_net('n', 500, 'Gamma', 2.8, 't', 0.25);
%
% Copyright (C) Gregorio Alanis-Lobato, 2014

%% Input parsing and validation
if nargin <= 10
    ip = inputParser;

    %Defaults
    N = 1000;
    ave_deg = 5;
    gamma = 2.5;
    T = 0;
    plot = 'yes';
    connected = 'no';

    addParamValue(ip, 'N', N, @(x) isnumeric(x) && isscalar(x));
    addParamValue(ip, 'ave_deg', ave_deg, @(x) isnumeric(x) && isscalar(x) && (x > 0 && x < N));
    addParamValue(ip, 'gamma', gamma, @(x) isnumeric(x) && isscalar(x) && x > 2);
    addParamValue(ip, 'T', T, @(x) isnumeric(x) && isscalar(x) && (x >= 0 && x <= 1));
    addParamValue(ip, 'plot', plot, @(x) strcmp(x, 'yes') || strcmp(x, 'no'));
    addParamValue(ip, 'connected', connected, @(x) strcmp(x, 'yes') || strcmp(x, 'no'));
    
    parse(ip, varargin{:});

    %Validated parameter values
    N = ip.Results.N;
    ave_deg = ip.Results.ave_deg;
    gamma = ip.Results.gamma;
    T = ip.Results.T;
    plot = ip.Results.plot;
    connected = ip.Results.connected;
else
    fprintf('Maximum number of paremeters exceeded. ');
    fprintf('This function only accepts the following parameters:\n');
    fprintf('\tN (optional, default = 1000)\n');
    fprintf('\tave_deg (optional, default = 5)\n');
    fprintf('\tgamma (optional, default = 2.5)\n');
    fprintf('\tT (optional, default = 0)\n');
    fprintf('\tplot (optional, default = ''yes'')\n');
    fprintf('\tconnected (optional, default = ''no'')\n');
    net = [];
    return;
end

%% Network construction
if T == 0
    c = (pi*ave_deg/2)*((gamma - 2)/(gamma - 1))^2;
else
    c = ave_deg*(sin(pi*T)/(2*T))*((gamma - 2)/(gamma - 1))^2;
end

R = 2*log(N/c);
alpha = (gamma - 1)/2;
node_coords = rand_polar_coords(N, R, alpha);

%Compute the hyperbolic distances between nodes
D = pdist2(node_coords, node_coords, @hyperbolic_dist);
D(logical(eye(N))) = 0;

%Compute the probability of connection for each node pair and form the
%final network
if T == 0
    p = heaviside(R - D);
    net = p;
    net(logical(eye(N))) = 0;
else
    p = 1 ./ (1 + exp((D - R)./(2*T)));
    rand_matrix = triu(rand(N), 1);
    rand_matrix = max(rand_matrix, rand_matrix');
    net = double(rand_matrix < p);
    net(logical(eye(N))) = 0;
end

if strcmp(connected, 'yes')
    [~, C] = graphconncomp(sparse(net), 'directed', 'false');
    %Create a cycle between disconnected components
    for i = 1:(N - 1)
        if C(i) ~= C(i + 1)
            net(i, i + 1) = 1;
            net(i + 1, i) = 1;
        end
    end
end

if strcmp(plot, 'yes')
    x = node_coords(:, 1) .* cos(node_coords(:, 2));
    y = node_coords(:, 1) .* sin(node_coords(:, 2));
    gplot(net, [x, y], 'k');
    hold on
    scatter(x, y, 20, node_coords(:, 2), 'filled');
end

%% SUPPORT FUNCTIONS
function points = rand_polar_coords(N, R, alpha)
%Generates N random points in a circle of radius R centred at (0, 0).
%Polar coordinates are returned.

theta = rand(N, 1) * (2 * pi);

%Each node is assigned a radial coordinate r in [0, R] with probability 
%   p(r) = a*exp(a*(r - R))

p = alpha * exp(alpha*((0:0.001:R) - R));
r = (randp(p, N, 1)/numel(p))*R;

points = [r theta];