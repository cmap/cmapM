function status = start_parallel
try
    if verLessThan('matlab', '7.0')
        if matlabpool('size') == 0
            matlabpool('open');
        end
        status = matlabpool('size')>0;
    else
        myPool = gcp('nocreate');
        if isempty(myPool)
            myPool = parpool();
        end
        status = ~isempty(myPool);
    end    
catch EM
    disp(EM)
    status=false;
end
