function status = stop_parallel
try
    if verLessThan('matlab', '7.0')
        isOpen = matlabpool('size')>0;
        if isOpen
            matlabpool('close');
        end
        status = matlabpool('size')==0;
    else
        myPool = gcp('nocreate');
        if ~isempty(myPool)
            myPool.delete
        end
        status = isempty(myPool);
    end
catch EM
    disp(EM)
    status = false;
end