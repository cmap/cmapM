function h = plot_constant(k, ishoriz, varargin)
% PLOT_CONSTANT Plot a constant line.
% H = PLOT_CONSTANT(K) plots a horizontal line at y=K
% H = PLOT_CONSTANT(K, ISHORIZ) plots a vertcal line at x=K if ISHORIZ is
% false.
% H = PLOT_CONSTANT(K, ISHORIZ, param1, value1,...) specify optional line
% attributes.
% Example: plot_constant(10, true, 'color','c','linewidth', 2)

if ~isvarexist('ishoriz')
    ishoriz = true;
end

config = struct('name', {'--show_label'},...
    'default', {true},...
    'help', {'Display text label'});
opt = struct('prog', mfilename, 'desc', 'Plot a constant line', 'undef_action', 'ignore');
[args, help_flag, used_args] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

rem_args = varargin(~used_args);
% if ~isvarexist(show_label)
%     show_label = true;
% end

if verLessThan('matlab', '8.4')
    h = graph2d.constantline(k, rem_args{:});
    if ~ishoriz
        h.changedependvar('x');
    end
else
    % graph2d not supported in 2014b 
    xl = xlim;
    yl = ylim;
    xd = 0.015*(xl(2)-xl(1));
    yd = 0.02*(yl(2)-yl(1));
    if ishoriz
    
        hold on
        h = plot(xl, [k, k], rem_args{:});
        if args.show_label
            text(xl(2)+xd, k, sprintf('%2.2g', k), 'fontsize', 10, 'color', 'r');
        end
    else
        
        hold on
        h = plot([k,k], yl, rem_args{:});
        if args.show_label
            text(k, yl(2)+yd, sprintf('%2.2g', k), 'fontsize', 10, 'color', 'r', 'rotation', 0, 'horizontalalignment', 'left');
        end
    end
    
end