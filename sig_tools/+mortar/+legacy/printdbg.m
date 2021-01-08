function printdbg(s, dbgflag)
%PRINTDBG Print string if debug flag is set.
% PRINTDBG(S, DBGFLAG)

if dbgflag
    fprintf ('%s\n',s)
end
end