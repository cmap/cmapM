function p = set_vdbpath(p)
% SET_VDBPATH Set location of virtual-db 

setenv('VDBPATH', p);
fprintf(1, 'Setting VDBPATH to %s', p);

end