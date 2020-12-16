function okay = spclose

try
    matlabpool close force local  ; 
    okay = 1; 
catch em
    disp(em)
    okay = 0; 
end