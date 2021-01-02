function wkdir = makeToolFolder(out_path, toolname, prefix, create_subdir)
% makeToolFolder Create a tool workfolder

if create_subdir
    wkdir = mktoolfolder(out_path, toolname, 'prefix', prefix);
else
    if isempty(out_path)
        out_path = pwd;
    end
    wkdir = out_path;
    if ~isdirexist(wkdir)
        mkdir(wkdir);
    end
end

end