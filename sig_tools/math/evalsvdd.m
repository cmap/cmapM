function k = evalsvdd(x,w)
% subroutine used to evaluate an svdd enclosure given new data x

k = w.a.*exp(-sqrt( sum((repmat(x,[size(w.sv,1),1])-w.sv).^2,2))/w.s) ; 


end