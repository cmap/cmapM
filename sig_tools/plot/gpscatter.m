function [h, lh, gn] = gpscatter(x,y,g,varargin)
%GPSCATTER   Scatter plot with grouping variable
%   GPSCATTER(X,Y,G) creates a scatter plot of the vectors X and Y grouped
%   by G.  Points with the same value of G are shown with the same color
%   and marker.  G is a grouping variable defined as a categorical
%   variable, vector, cell array of strings, or string matrix, and it must
%   have the same number of rows as X and Y.  Alternatively G can be a cell
%   array of grouping variables (such as {G1 G2 G3}) to group the values in
%   X by each unique combination of grouping variable values.  Use the data
%   cursor to read precise values and observation numbers from the plot.
%
%   GPSCATTER(X,Y,G, param1, value1,...) specify optional parameters:
%   'clr' : String or three-column matrix specifying marker colors
%   'sym' : String, marker symbols. See PLOT for a list of valid symbols.
%           Default is '.'
%   'size' : Area of each marker (in points^2), Can be a vector of size X
%            or a scalar. If size is a scalar all points are plotted in the
%            same size.
%   'doleg' : boolean, disable legends if false. Default is true
%   'xnam' : String, Xlabel
%   'ynam' : String, Ylabel
%   'location' : String, legend location. See LEGEND
%   'filled' : boolean, fill markers if true. Default is false
%   'palette' : three-column matrix, color palette to use
%
%   Example:  Scatter plot of car data coded by country.
%      load carsmall
%      gpscatter(Weight, MPG, Origin)
%
%   See also GRPSTATS, GRP2IDX.

pnames = {'clr', 'sym', 'size',...
    'doleg', 'xnam', 'ynam',...
    'location', 'filled', 'palette'};
dflts = {'', '.', [],...
    'on', inputname(1), inputname(2),...
    'best', false, ''};
arg = parse_args(pnames, dflts, varargin{:});

% error(nargchk(2,9,nargin,'struct'));
% 
% % Default colors, markers, etc.
% if (nargin < 4), clr = ''; end
% if (nargin < 5) || isempty(sym), sym = '.'; end
% if (nargin < 6), siz = []; end
% if (nargin < 7), doleg = 'on'; end
% if (nargin < 8), xnam = inputname(1); end
% if (nargin < 9), ynam = inputname(2); end

% What should go into the plot matrix?
arg.doleg = strcmp(arg.doleg, 'on');

% Don't plot anything if either x or y is empty
if isempty(x) || isempty(y),
   if nargout>0
       h = [];
   end
   return
end

if (ndims(x)==2) && any(size(x)==1), x = x(:); end
if (ndims(y)==2) && any(size(y)==1), y = y(:); end

if ndims(x)>2 || ndims(y)>2
   error('stats:gpscatter:MatrixRequired',...
         'X and Y must be 2-D.');
end
if size(x,1)~=size(y,1)
   error('stats:gpscatter:InputSizeMismatch',...
         'X and Y must have the same length.');
end

if (nargin > 2) && ~isempty(g)
   [g,gn,ignore1,ignore2,maxgrp] = mgrp2idx(g,size(x,1),','); %#ok<ASGLU>
   sz = accumarray(g, ones(size(g)));
   [~, srt_ord] = sort(sz, 'descend');
   [~, rank_ord] = sort(srt_ord);
   gn = gn(srt_ord);
   g = rank_ord(g);      
   ng = max(g);
else
   g = [];
   gn = [];
   ng = 1;
   maxgrp = 1;
end

if (~isempty(g)) && (length(g) ~= size(x,1)),
   error('stats:gpscatter:InputSizeMismatch',...
         'There must be one value of G for each row of X.');
end

if (isempty(arg.size))
   arg.size = repmat(get(0, 'defaultlinemarkersize'), size(arg.sym));
   if any(arg.sym=='.'),
      units = get(gcf,'units');
      set(gcf,'units','pixels');
      pos = get(gcf,'Position');
      set(gcf,'units',units);
      arg.size(arg.sym=='.') = max(1,min(15, round(15*min(pos(3:4))/size(x,1))));
   end
end

newplot;
if isempty(arg.clr)
%     arg.clr = hsv(maxgrp);
    arg.clr = get_palette(maxgrp);
end
hh = iscatter(x, y, g, arg.clr, arg.sym, arg.size);

% palette specified, override defaults.
if isequal(class(arg.palette), 'containers.Map')
    for ii=1:length(gn)
        p = arg.palette(gn{ii});
        if isa(p, 'double') && isequal(numel(p), 3)
            set(hh(ii), 'color', p);
        else
            set(hh(ii), 'color', get_color(arg.palette(gn{ii})))
        end
    end
end

if arg.filled
    for ii=1:length(hh)
        set(hh(ii), 'markerfacecolor', get(hh(ii), 'color'));
    end
end

% Label plots
if (~isempty(arg.xnam)), xlabel(texify(deblank(arg.xnam))); end
if (~isempty(arg.ynam)), ylabel(texify(deblank(arg.ynam))); end

% Add behavior object to lines, to customize datatip text
dataCursorBehaviorObj = hgbehaviorfactory('DataCursor');
set(dataCursorBehaviorObj,'UpdateFcn',{@gpscatterDatatipCallback,arg.xnam,arg.ynam});
for i=1:ng
    hgaddbehavior(hh(i),dataCursorBehaviorObj);
    setappdata(hh(i),'group',i);
    if ~isempty(gn)
        setappdata(hh(i),'groupname',gn{i});
    end
    if ~isempty(g)
        gind = find(g==i);
        setappdata(hh(i),'gind',gind);
    end
end

% Create legend if requested
if (arg.doleg && ~isempty(gn))
   t = find(ismember(1:size(gn,1),g));
   lh = legend(hh(t), texify(gn(t,:)), 'location', arg.location);
else
    lh = [];
end

% Nudge X axis limits if points are too close
xlim = get(gca, 'XLim');
d = diff(xlim);
xlim(1) = min(xlim(1), min(min(x))-0.05*d);
xlim(2) = max(xlim(2), max(max(x))+0.05*d);
set(gca, 'XLim', xlim);

if (nargout>0), h = hh; end

% Store information for gname
set(gca, 'UserData', {'gpscatter' x y g});

% -----------------------------
function datatipTxt = gpscatterDatatipCallback(obj,evt,xnam,ynam)

target = get(evt,'Target');
ind = get(evt,'DataIndex');
pos = get(evt,'Position');

group = getappdata(target,'group');
groupname = getappdata(target,'groupname');
gind = getappdata(target,'gind');

if isempty(xnam)
    xnam = 'x';
end
if isempty(ynam)
    ynam = 'y';
end
if isempty (gind)
    % One group
    % Leave group name alone, it may be empty
    % Line index number is the same as the original row
    obsind = ind;
else
    % Multiple groups
    % If group name not given, assign it its number
    if isempty(groupname)
        groupname = num2str(group);
    end
    % Map line index to the original row
    obsind = gind(ind);
end

datatipTxt = {...
    [xnam ': ' num2str(pos(1))]...
    [ynam ': ' num2str(pos(2))]...
    ''...
    ['Observation: ' num2str(obsind)]
    };

if ~isempty(groupname)
    datatipTxt{end+1} = ['Group: ' groupname];
end

