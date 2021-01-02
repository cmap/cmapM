function [yhat,fit_obj] = svm_pred(x_train,x_test,ytrain,ker,p1,lambda)
% Support Vector Regression prediction via kernel matrix
% see also svm_fit

H = evalkernel(x_train,x_train,ker,p1); 
alpha = pinv(H*H' + lambda*ones(size(H,1)))*ytrain ; 

H = evalkernel(x_train,x_test,ker,p1); 
yhat = zeros(size(x_test,1),size(ytrain,2)); 
W = H*alpha; s = std(ytrain); m = mean(ytrain); 
parfor i = 1 : size(yhat,1)
    yhat(i,:) = W(i,:).*s + m  ; 
end
fit_obj.operator_mat = W; 
fit_obj.scale = s; 
fit_obj.shift = m; 
fit_obj.H = H; 
fit_obj.alpha = alpha; 