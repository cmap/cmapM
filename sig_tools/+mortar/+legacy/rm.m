function okay = rm(pathname)

if isdir(pathname)
    okay = system(['rm -r -f ',pathname]); 
    okay = ~okay; 
else
    error('delete individual files manually...'); 
end