function isok = check_dup_id(id, error_flag)
% CHECK_DUP_ID Check if ids are unique
%   ISOK = CHECK_DUP_ID(ID, FAIL_FLAG) Checks if ID has duplicates and
%   reports an error if FAIL_FLAG is true or a warning of false.
dups = duplicates(id);
isok = true;
if ~isempty(dups)
    isok = false;
    disp(dups)
    if error_flag        
        error('n=%d Duplicate ids found', length(dups))
    else
        warning('n=%d Duplicate ids found', length(dups))
    end
end

end