function y = safelog(x)

x(x<=0) = 0.5; 
y = log(x); 