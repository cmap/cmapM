function d = angular_dist(XI, XJ)
%Computes the angular distance between point XI (1 x 1) and the m points
%stored in XJ (m x 1). The resulting distances are stored in d.
%INPUT
%   XI -> A single value representing the angular position of a point on a
%         ring.
%   XJ -> The angular position of m points located around a ring.
%OUTPUT
%   d -> The minimum angular distance between XI and the m points stored in
%        XJ. This distance is computed as Dij = pi - |pi - |Xi - Xj|| for
%        points Xi and Xj, i ~= j.
%
% Copyright (C) Gregorio Alanis-Lobato, 2014

d =  pi - abs(pi - abs(XI - XJ(:, 1))); %Angular separation between points
