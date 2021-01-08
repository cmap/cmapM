function [tf, missing] = check_struct_field(s, reqfn, fail_action)
% CHECK_STRUCT_FIELD Check if required fields are present in a structure
% [TF, MISS] = CHECK_STRUCT_FIELD(S, F, ACTION) Checks if fields F are 
%   present in structure S. If any fields are missing then ACTION is
%   performed, can be 'silent', 'warn' or 'error'. TF is true if all
%   required fields are present, false otherwise. MISS is a cell array of
%   missing fields.

is_in_s = isfield(s, reqfn);
tf = all(is_in_s);
missing = reqfn(~is_in_s);
if ~tf
    msg = sprintf(['%d/%d Required fields were missing from input. ',...
                  'See preceeding output for a list'],...
                   nnz(~is_in_s), numel(is_in_s));
    switch fail_action
        case 'silent'
        case 'warn'
            disp(missing)
            warning(msg);
        case 'error'
            disp(missing)
            error(msg);
        otherwise
            error('Unknown fail action, expected {silent,warn,error} got %s', fail_action);
    end
end

end