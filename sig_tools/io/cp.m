function status = cp(src, dest)
% CP Copy a file (alternative to copyfile).
% STATUS = CP(SRC, DEST)
% See also: copyfile
status = system(sprintf('cp %s %s', src, dest));
end
