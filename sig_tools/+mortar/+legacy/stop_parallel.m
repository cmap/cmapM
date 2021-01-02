function status = stop_parallel
try
    if matlabpool('size') > 0
        matlabpool ('close');
        status = true;
    end
catch EM
    disp(EM)
    status=false;
end