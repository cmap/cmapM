function clean
% CLEAN Clear workspace and close all figures

evalin('base', 'fclose all;');
evalin('base', 'close all;');
evalin('base', 'clear all;'); 
evalin('base', 'clear import;'); 
end