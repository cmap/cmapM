function adjust_boxplot_label(ah, varargin)
% ADJUST_BOXPLOT_LABEL Adjust label properties of a boxplot.
%   ADJUST_BOXPLOT_LABEL
%   ADJUST_BOXPLOT_LABEL(AH)
%   ADJUST_BOXPLOT_LABEL(AH, param1, value1,...)
%   'halign' : string, horizontal alignment. left | center | right.
%   'valign' : string, vertical alignment. top | cap | middle | bottom.
%   'x_offset' : scalar, x position of the label in normalized units
%   'y_offset' : scalar, y position of the label in normalized units
%   'rotation' : scalar, rotation of the label
%   'fontsize' : scalar, font size
%   'fontweight' : string, font weight {normal} | bold | demi | light
%   'color' : ColorSpec, A three-element RGB vector or one of the
%               predefined names, specifying the text color.

if ~isvarexist('ah')
    ah = gca;
end

pnames = {'halign', 'valign',...
          'x_offset', 'y_offset', 'rotation',...
          'fontsize', 'fontweight', 'color'};
dflts = {'', '',...
         nan, nan, nan,...
         12, 'bold', 'k'};
args = parse_args(pnames, dflts, varargin{:});
% valid_h = {'left', 'center', 'right'};
% valid_v = {'top', 'cap', 'middle', 'bottom'};
if ~isequal(length(args.color), 1)
    args.color = str2num(args.color); %#ok<ST2NM>
end

% default settings for different orientations
% horizontal orientation
dh = struct('labelaxis', 'y',...
            'halign', 'right',...
            'valign', 'middle',...
            'x_offset', -0.01,...
            'y_offset', 0,...
            'rotation', 0);
        
% vertical orientation        
dv = struct('labelaxis', 'x',...
            'halign', 'center',...
            'valign', 'bottom',...
            'x_offset', 0,...
            'y_offset', -0.082,...
            'rotation', 0);

%% adjust labels
boxparent = getappdata(ah, 'boxplothandle');
assert(~isempty(boxparent), 'Boxplot not found in supplied axis')
adata = getappdata(boxparent);
assert(~isempty(adata), 'Boxplot not found in supplied axis')
nt = length(adata.labelhandles);

switch adata.labelaxis
    case 'y'
        opt = get_settings(dh, args);
        set(adata.labelhandles, 'horizontalalignment', opt.halign,...
            'verticalalignment', opt.valign,...
            'rotation', opt.rotation,...
            'units', 'normalized');
        for ii=1:nt
            pos = get(adata.labelhandles(ii), 'position');
            pos = [opt.x_offset, pos(2:3)];
            set_label_prop(adata.labelhandles(ii), pos, args);
        end
    case 'x'
        opt = get_settings(dv, args);
        set(adata.labelhandles, 'horizontalalignment', opt.halign,...
            'verticalalignment', opt.valign,...
            'rotation', opt.rotation,...
            'units','normalized');
        for ii=1:nt
            pos = get(adata.labelhandles(ii), 'position');
            pos = [pos(1), opt.y_offset, pos(3)];
            set_label_prop(adata.labelhandles(ii), pos, args);
        end
    otherwise
        error('Invalid labelaxis : %s', adata.labelaxis);        
end

% disable the boxplot callbacks to avoid repositioning labels
lh = getappdata(boxparent, 'boxlisteners');
for ii=1:length(lh)
    if ishandle(lh{ii})
        delete(lh{ii});
    end
end
end

function set_label_prop(th, pos, args)
set(th,...
    'position', pos, 'fontweight', args.fontweight,...
    'fontsize', args.fontsize, 'color', args.color);
end

function dflts = get_settings(dflts, args)
fn = intersect(fieldnames(dflts), fieldnames(args));
for ii=1:length(fn)
    if ~isempty(args.(fn{ii})) && all(~isnan(args.(fn{ii}))) && ...
            ~isequal(args.(fn{ii}), dflts.(fn{ii}))
        dflts.(fn{ii}) = args.(fn{ii});
    end
end
end
