function status = start_parallel
try
    if matlabpool('size') == 0
        matlabpool ('open');
        status = true;
    end
catch EM
    disp(EM)
    status=false;
end
