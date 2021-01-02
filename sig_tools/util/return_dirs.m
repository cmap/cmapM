function dirs = return_dirs(pathname)

dirs = dir(pathname); 
drop = zeros(length(dirs),1); 

for i = 1 : length(dirs)
    if strcmp(dirs(i).name(1),'.')
        drop(i) = 1; 
    elseif ~dirs(i).isdir
        drop(i) = 1; 
    end
end
dirs(logical(drop)) = [];