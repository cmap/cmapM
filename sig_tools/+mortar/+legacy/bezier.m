function b = bezier(p, t)
% BEZIER compute Bezier curves.
%   B = BEZIER(P, T)

n = size(p,1);
if n<2
    error('At least two control points must be specified');
end
t=t(:);
switch(n)
    case 2
        disp('linear')
        b=bsxfun(@plus, p(1,:), bsxfun(@times, (p(1,:) - p(2, :)), t));
    case 3
        disp('quadratic')
        b = bsxfun(@times, p(1,:), (1-t).^2) + ...
        bsxfun(@times, p(2,:), 2*(1-t).*t) + ...
        bsxfun(@times, p(3,:), t.^2);
    case 4
        disp('cubic')
        b = bsxfun(@times, p(1,:), (1-t).^3) + ...
            bsxfun(@times, p(2,:), 3*(1-t).^2.*t) + ...
            bsxfun(@times, p(3, :), 3*(1-t)*t.^2) + ...
            bsxfun(@times, p(4, :), t.^3);
    otherwise
        %todo add general definition
        error('Degress > 3 not supported')
end

end