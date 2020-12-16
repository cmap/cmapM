function H = evalkernel(x,y,ker,p1)
% Subroutine used for SVM regression. H is the hessian matrix
% evaluated in the context of x and y given ker and paramterer p1
% see also svkernel, parfor

n = size(x,1); 
m = size(y,1); 

seq = 1:n ; 
ix = zeros(n*m,2); 
ix(1:n,:) = [repmat(1,[n,1]),seq(:)]; 
for i = 2 : m
    space = ((i-1)*n + 1) : i*n ; 
    ix(space,:) = [repmat(i,[n,1]),seq(:)]; 
end
H = zeros(n*m,1); 
fprintf(1,'%s\n',horzcat('Number of flops: ',num2str(n*m))); 

tic ; 
parfor i = 1 : n*m
    H(i) = svkernel(ker,y(ix(i,1),:),x(ix(i,2),:),p1); 
end
fprintf(1,'%s\n',horzcat('Kernel matrix evaluation took ',...
    num2str(toc/60),' minutes.')); 
H = reshape(H,n,m)'; 
