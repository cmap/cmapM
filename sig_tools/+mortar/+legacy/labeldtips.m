% LABELDTIPS Callbal fn to diaplay cstom datatips
% Display an observation's Y-data and label for a datatip
% obj          Currently not used (empty)
% event_obj    Handle to event object
% xydata       Entire data matrix
% labels       State names identifying matrix row
% xymean       Ratio of y to x mean (avg. for all obs.)
% output_txt   Datatip text (string or string cell array)
% This datacursor callback calculates a deviation from the
% expected value and displays it, Y, and a label taken
% from the cell array 'labels'; the data matrix is needed
% to determine the index of the x-value for looking up the
% label for that row. X values could be output, but are not.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

function output_txt = labeldtips(obj,event_obj,...
                      xydata,labels,xymean)

disp('callback');
output_txt='callback';
% pos = get(event_obj,'Position');
% x = pos(1); y = pos(2);
% output_txt = {['Y: ',num2str(y,4)]};
% ydev = round((y - x*xymean));
% ypct = round((100 * ydev) / (x*xymean));
% output_txt{end+1} = ['Yobs-Yexp: ' num2str(ydev) ...
%                      '; Pct. dev: ' num2str(ypct)];
% idx = find(xydata == x,1);  % Find index to retrieve obs. name
% % The find is reliable only if there are no duplicate x values
% [row,col] = ind2sub(size(xydata),idx);
% output_txt{end+1} = cell2mat(labels(row));
