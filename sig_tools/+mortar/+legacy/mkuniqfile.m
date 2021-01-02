% MKUNIQFILE Generate a unique filename
function newfname = mkuniqfile(fname, folder)

if isfileexist(fullfile(folder, fname))
    [p,f,e] = fileparts(fname);
    ctr = 1;
    newfname = sprintf('%s.%d%s',f,ctr,e);
    while isfileexist(fullfile(folder, newfname))
        ctr = ctr + 1;
        newfname = sprintf('%s.%d%s',f,ctr,e);
    end
else
        newfname = fname;
end 