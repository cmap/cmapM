function x = fix_annotation_class(x)
nc = size(x, 2);
for ii=1:nc
    c = unique(cellfun(@class, x(:, ii), 'uniformoutput', false));
    % if multiclass cell convert to string
    if length(c) > 1
        x(:, ii) = cellfun(@stringify, x(:, ii), 'uniformoutput',false);
    end
end
end