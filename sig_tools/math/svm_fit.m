function [alpha,bias] = svm_fit(x_train,ytrain,ker,p1,lambda)
% see also svm_pred

x_train = double(x_train); 
ytrain = double(ytrain); 
H = evalkernel(x_train,x_train,ker,p1); 
alpha = pinv(H*H' + lambda*ones(size(H,1)))*ytrain ; 

bias = mean(ytrain); 