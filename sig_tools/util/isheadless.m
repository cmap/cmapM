function tf = isheadless
% ISHEADLESS Checks if matlab session is running in headless mode.
%   TF = ISHEADLESS
%     tf = isempty(com.mathworks.mde.desk.MLDesktop.getInstance.getMainFrame);    
    % check if MWT is available
    tf = isequal(usejava('mwt'), 0);
end