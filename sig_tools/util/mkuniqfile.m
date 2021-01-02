% MKUNIQFILE Generate a unique filename
function [newfname, fullpath] = mkuniqfile(fname, folder)

if isfileexist(fullfile(folder, fname))
    [p,f,e] = fileparts(fname);
    ctr = 1;
    newfname = sprintf('%s.%d%s',f,ctr,e);
    fullpath = fullfile(folder, newfname);
    while isfileexist(fullpath)
        ctr = ctr + 1;
        newfname = sprintf('%s.%d%s',f,ctr,e);
        fullpath = fullfile(folder, newfname);
    end
else
        newfname = fname;
        fullpath = fullfile(folder, fname);
end 