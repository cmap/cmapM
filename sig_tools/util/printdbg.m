%PRINTDBG Print string if debug flag is set.
% PRINTDBG(S, DBGFLAG)
function printdbg(s, dbgflag)
    if dbgflag
        fprintf ('%s\n',s)
    end
end