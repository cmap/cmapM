function okay = spopen

try
    if matlabpool('size') == 0
        matlabpool open ; 
    end
    okay = 1; 
catch em
    disp(em); 
    fprintf(1,'%s\n','Parallel toolbox not installed'); 
    okay = 0; 
end