function spexit

try
    matlabpool close force  ; 
    exit
catch em
    disp(em);
    exit
end