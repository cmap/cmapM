function open_dir(pathname)
if nargin == 0
    pathname = uigetdir ; 
end
files = dir(fullfile(pathname,'*.m')); 
for i = 1 : length(files)
    open(files(i).name); 
end