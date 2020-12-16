function figlist = savefigures(varargin)
% SAVEFIGURES Save currently open figures to disk.
%   F = SAVEFIGURES Saves all open figures to the current working folder in
%   PNG format.
%
%   F = SAVEFIGURES(param1, val1, param2, val2,...) Specify optional arguments:
%
%   'fmt' String. Output file format. See PRINT for supported formats. In
%               addition svg format is supported via PLOT2SVG. Default is
%               png
%   'out' String. Output folder. Default is the current working folder.
%   'mkdir' Logical. If true, creates a unique subfolder under out. Default
%                is true
%   'sortord' Logical. If true the figures are saved in the order they were
%                created. Default is true
%   'exclude' [Array of handles]. If non empty, ignores the list of provided
%                figure handles. Default is []
%   'overwrite' Logical. If true overwrites existing files, otherwise unique
%               filenames are generated. Default is false.
%   'lower' Logical. If true converts filenames to lowercase. Default is
%               false.
%   'closefig' Logical. If true closes figures after they have been saved.
%               Default is false.
%   'antialias' Logical. If true applies anti-aliasing via MYAA. Default is
%               false.
%   'verbose' Logical. If true prints debugging messages. Default is true.
%
%   'renderer' String. {'opengl', 'painters'} Specify the output renderer 
%               for plots. For vector graphics formats of complex figures 
%               such as heatmaps, use the 'painters' renderer. Default is
%               'opengl'

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

toolname = mfilename;
pnames = {'--fmt', '--out' , '--mkdir', '--sortord', '--include', '--exclude',...
    '--overwrite','--lower', '--closefig', '--antialias','--verbose', '--renderer'};
dflts = {'png', '.', true, true, [], [],...
    false, false, false, false, true, 'opengl'};
config = struct('name', pnames, 'default', dflts);
opt = struct('prog', mfilename, 'desc', 'Save currently open figures to disk.');
[args, help_flag] = mortar.common.ArgParse.getArgs(config,opt, varargin{:});
if ~help_flag
    figs_all = findobj('type', 'figure');
    if isa(figs_all, 'matlab.ui.Figure')
        figs_all = [figs_all.Number]';
    end
    
    if ~isempty(args.include)
        if isa(args.include, 'matlab.ui.Figure')
            include_handle = [args.include.Number]';
            [hf, ord] = intersect(figs_all, include_handle);
        else
            [hf, ord] = intersect(figs_all, args.include);
        end        
    else
        if isa(args.exclude, 'matlab.ui.Figure')
            exclude_handle = [args.exclude.Number]';
            [hf, ord] = setdiff(figs_all, exclude_handle);
        else
            [hf, ord] = setdiff(figs_all, args.exclude);
        end        
    end
    
    % sorted by default
    if ~args.sortord
        hf = hf(sort(ord));
    end
    nf = length(hf);
    figlist=cell(nf,1);
    
    %search these fields for a label
    namefields = {'name', 'tag'};
    
    %create sub folder by default
    if args.mkdir
        wkdir = mkworkfolder(args.out, toolname);
    else
        if ~isdirexist(args.out)
            mkdir(args.out)
        end
        wkdir = args.out;
    end
    
    dbg (args.verbose, 'Saving %d figure(s) to %s', nf, wkdir);
    
    for ii=1:nf
        if isheadless
            % for compatibiltiy with headless mode figure generation
            dbg(args.verbose, 'Headless mode: switching renderer to painters');
            set(hf(ii), 'Renderer', 'painters')
        else
            set(hf(ii), 'Renderer', args.renderer)
        end
        
        for jj=1:length(namefields)
            lbl = get(hf(ii), namefields{jj});
            if args.lower
                lbl = lower(lbl);
            end
            if ~isempty(lbl)
                [isvalid, lbl]= validate_fname(lbl);
                break;
            end
        end
        % try using the title of the current axis
        if isempty(lbl)
            %         figure(hf(ii))
            hax=findobj(get(hf(ii),'children'),'type','axes');
            if args.antialias
                myaa
            end
            for jj=1:length(hax)
                s = get(get(hax(jj), 'title'),'string');
                if args.lower
                    s = lower(s);
                end
                if ~isempty(s)
                    [isvalid, lbl] = validate_fname(strrep(s, ' ', '_'));
                    break;
                end
            end
        end
        
        if isempty(lbl)
            lbl = sprintf('figure_%d',hf(ii));
        end
        % use .eps extension for all .eps* format files
        ext = regexprep(args.fmt, '^eps.*', 'eps');
        if args.overwrite
            figfile = sprintf('%s.%s', lbl, ext);
        else
            figfile = mkuniqfile(sprintf('%s.%s', lbl, ext), wkdir);
        end
        figlist{ii} = fullfile(wkdir, figfile);
        % svg format
        if strcmpi('svg', args.fmt)
            plot2svg(figlist{ii}, hf(ii));
        else
            
            dbg(args.verbose, '%s', figfile);
            saveas(hf(ii), figlist{ii}, args.fmt);
        end
    end
    if args.closefig
        close(hf);
    end
else
    figlist = [];
end