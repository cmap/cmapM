function mkpdf(ofname, imlist, varargin)
% MKPDF Create LaTeX report file given a list of figures or tables.
%
% MKPDF(OFNAME, IMLIST) Creates a TeX file OFNAME given a cell
% array of pathnames to figures IMLIST.
%
% MKTEX_FIGREPORT(OFNAME, IMLIST, 'PARAM1', val1, 'PARAM2', val2, ...)
% specifies optional parameter name/value pairs.
% 'title'       string. Appends a title to the report.
%
% 'arg'         structure, such as that returned by GETARGS2. Creates a
%               parameter table
%
% 'group'       cell array or | delimited string. Adds captions for
%               each figure.
%
% 'tile'        string. Specifies custom tiling options.
%               <num_images>:rowxcol, e.g. '7:3x3,5:3x2'
%
% 'caption'     cell array or | delimited string. Captions for each figure
%               or element in IMLIST. By default filenames are used for
%               images.
%
%
% Example:
%
% h1 = figure
% x=rand(100,1);
% y = rand(100,1);
% scatter(x,y)
% h2 = figure
% [X,Y,Z] = peaks(30);
% surfc(X,Y,Z)
% colormap hsv
% axis([-3 3 -3 3 -10 5])
% print (h1, '-dpng', 'fig1.png')
% print (h2, '-dpng', 'fig2.png')
% mkpdf('report.tex', {'fig1.png', 'fig2.png'}, 'title', 'Report','caption', {'Figure 1','Figure 2'})
% pdflatex('report.tex','cleanup', true)
%
% See also PDFLATEX

%TODO:
% support per slide config settings
% add tooltips
% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

pnames = {'title', 'author', 'institute', 'date', ...
    'arg', 'navigation', 'caption', 'group', ...
    'tile', 'groupcaption', 'slidetitle', 'showfooter',...
    'showcaption', 'showpagenumber','themecolor', 'mktitle',...
    'maxstrlen', 'imclass'};
dflts =  {'', '', '', '',...
    struct([]), false, {}, {},...
    '', {}, {}, true,...
    true, true, 'Black', true,...
    255, {}};

arg = parse_args(pnames, dflts, varargin{:});
if isempty(arg.groupcaption)
    arg.showcaption = false;
end
% get optimal page layout and scaling
[tile_dict, scale_dict, use_fixed_tile] = get_tile_map('tile', arg.tile,...
    'showfooter', arg.showfooter, 'showcaption', arg.showcaption);

if any(cellfun(@isempty, imlist))
    error('Imlist cant be empty');
end

nimlist = length(imlist);
% type of entry in imlist
imclass = cell(nimlist, 1);
% entry labels
if isempty(arg.imclass)
    lbl = cell(nimlist, 1);
    pt_ctr = 1;
    lt_ctr = 1;
    for ii=1:nimlist
        imclass{ii} = class(imlist{ii});
        switch imclass{ii}
            case 'char'
                % use filenames as captions
                if isfileexist(imlist{ii})
                    [~, lbl{ii}, ~] = fileparts(imlist{ii});
                    imclass{ii} = 'image';
                else
                    error('File doesnt exist: %s', imlist{ii})
                end
            case 'struct'
                if isequal(length(imlist{ii}), 1)
                    lbl{ii} = sprintf('Parameter table %d', pt_ctr);
                    imclass{ii} = 'param_table';
                    pt_ctr = pt_ctr + 1;
                else
                    lbl{ii} = sprintf('Long table %d', lt_ctr);
                    imclass{ii} = 'long_table';
                    lt_ctr = lt_ctr + 1;
                end
            otherwise
                error('Unknown input type')
        end
    end
    if isempty(arg.caption)
        arg.caption = lbl;
    end
else
    imclass = arg.imclass;
end

%groups are defined
if ~isempty(arg.group)
    if ischar(arg.group)
        arg.group = tokenize(arg.group,'|');
    end
    [gp, gpidx] = getcls(arg.group);
    nim = length(gp);
    % slidetitle is not user defined so use group
    if isempty(arg.slidetitle)
        arg.slidetitle = gp;
    end
    if ~isequal(length(imlist), length(gpidx))
        error('Grouping vector not equal to the number of images')
    end
else
    nim = length(imlist);
    gpidx = 1:nim;
    arg.slidetitle = arg.caption;
end


if nim
    fid = fopen(ofname, 'wt');
    fprintf(fid, '\\documentclass[xcolor=dvipsnames, 10pt]{beamer}\n');
    %preamble
    fprintf(fid, '\\title{%s}\n', texify(arg.title));
    fprintf(fid, '\\author{%s}\n', texify(arg.author));
    fprintf(fid, '\\institute{%s}\n', texify(arg.institute));
    fprintf(fid, '\\date{%s}\n', texify(arg.date));
    %tooltips package
    %fprintf(fid, '\\usepackage{cooltooltips}\n');
    %beamer themes and options
    fprintf(fid, '\\usecolortheme[named=%s]{structure}\n', arg.themecolor);
    %footer
    if arg.showfooter && ~isempty(arg.institute)
        fprintf(fid, '\\useoutertheme{infolines}\n');
    elseif arg.showfooter && (~isempty(arg.title) || ~isempty(arg.author))
        fprintf(fid, '\\useoutertheme{split}\n');
    elseif arg.showfooter && arg.showpagenumber
        fprintf (fid, ['\\setbeamertemplate{footline}{\\hspace*{.5cm}',...
            '\\scriptsize{\\insertauthor\\hspace*{50pt}',...
            '\\hfill\\insertframenumber\\hspace*{.5cm}}}\n']);
    else
        fprintf (fid, '\\useoutertheme{default}\n');
    end
    fprintf(fid, '\\usetheme[height=6mm]{Rochester}\n');
    fprintf(fid, '\\usefonttheme{structurebold}\n');
    fprintf(fid, '\\setbeamertemplate{caption}[numbered]\n');
    fprintf(fid, '\\setbeamerfont{caption}{size=\\small, series=\\bfseries}\n');
    % modify defaults in subfigure
    fprintf(fid, '\\usepackage{subfigure}\n');
    %fprintf(fid, '\\renewcommand{\\subfigtopskip}{0pt}\n');
    %fprintf(fid, '\\renewcommand{\\subfigbottomskip}{0pt}\n');
    fprintf(fid, '\\renewcommand{\\subcapsize}{\\tiny}\n');
    fprintf(fid, '\\renewcommand{\\subcapfont}{\\bf}\n');
    % subfigure numbering
    fprintf(fid, '\\renewcommand{\\thesubfigure}{\\thefigure\\alph{subfigure}.}\n');
    % subtable numbering
    fprintf(fid, '\\renewcommand{\\thesubtable}{Table \\thetable\\alph{subtable}.}\n');
    fprintf(fid, '\\addtocounter{table}{1}\n');
    fprintf(fid, '\\begin{document}\n');
    if ~arg.navigation
        fprintf(fid, '\\setbeamertemplate{navigation symbols}{}\n');
    end
    % title page
    if arg.mktitle
        fprintf (fid, '\\frame{\n');
        fprintf(fid,'\\centering\n');
        if ~isempty(arg.title)
            fprintf(fid,'%s\\\\\n', texify(arg.title));
        end
        if ~isempty(arg.author) && ~isempty(arg.institute)
            fprintf(fid,'%s (%s)\\\\\n', texify(arg.author), texify(arg.institute));
        end
        if ~isempty(arg.date)
            fprintf(fid,'%s\\\\\n', texify(arg.date));
        else
            fprintf(fid,'%s\\\\\n', datestr(now));
        end
        fprintf(fid, '}\n');
    end
    
    % create slides
    for ii=1:nim
        fprintf(fid,'\\frame{\n');
        fprintf(fid,'\\frametitle {%s}\n', texify(arg.slidetitle{ii}));
        thisgp = find(gpidx==ii);
        nthisgp = length(thisgp);
        thisclass = unique_ord(imclass(thisgp));
        %scaling
        if use_fixed_tile
            imscale = scale_dict(arg.tile);
        elseif tile_dict.isKey(nthisgp)
            imscale = scale_dict(tile_dict(nthisgp));
        else
            imscale = 0.80 / length(thisgp);
        end
        for jj=1:length(thisclass)
            switch thisclass{jj}
                case 'image'
                    %images in this group
                    eidx = thisgp(strmatch('image', imclass(thisgp)));
                    fprintf(fid,'\\begin{figure}\n');
                    fprintf(fid,'\\centering\n');
                    %subfigures with subcaptions
                    for kk=1:length(eidx)
                        [fp, fn, fe] = fileparts(imlist{eidx(kk)});
                        fe = strrep(fe, '.', '');
                        fprintf(fid, '\\subfigure[%s] {\n', texify(arg.caption{eidx(kk)}));
                        fprintf(fid, ['\\includegraphics',...
                            '[type=%1$s, ext=.%1$s, read=.%1$s,',...
                            'width=%2$1.3f\\textwidth] {%3$s}\n'], ....
                            fe, imscale, fullfile(fp,fn));
                        fprintf(fid, '}\n');
                    end
                    % figure caption
                    if arg.showcaption
                        fprintf(fid,'\\caption {%s}\n', texify(arg.groupcaption{ii}));
                    else
                        % adjust counters
                        fprintf(fid, '\\addtocounter{figure}{1}\n');
                        fprintf(fid, '\\setcounter{subfigure}{0}\n');
                    end
                    fprintf(fid,'\\end{figure}\n');
                    
                case 'param_table'
                    %tables in this group
                    eidx = thisgp(strmatch('param_table', imclass(thisgp)));
                    fprintf(fid,'\\begin{table}\n');
                    fprintf(fid,'\\centering\n');
                    for kk=1:length(eidx)
                        fprintf(fid, '\\subtable[%s] {\n', texify(arg.caption{eidx(kk)}));
                        fprintf(fid, '\\resizebox{%1.3f\\textwidth}{!}{\n', imscale);
                        %fprintf(fid, beginTable);
                        fprintf(fid, '\\tiny\\begin{tabular}{|l|l|}\\hline\n');
                        tbl = imlist{eidx(kk)};
                        param = fieldnames(tbl);
                        for k=1:length(param)
                            val = stringify(tbl.(param{k}));
                            if iscell(val)
                                val = print_dlm_line2(val, 'dlm', ':');
                            end
                            val = strtrunc(val, arg.maxstrlen);
                            fprintf (fid, '\\bf{%s} & %s\\\\\n', texify(param{k}), texify(val));
                        end
                        fprintf(fid, '\\hline\n\\end{tabular}}\n');
                        fprintf(fid,'}\n');
                    end
                    % figure caption
                    if arg.showcaption
                        fprintf(fid,'\\caption {%s}\n', texify(arg.groupcaption{ii}));
                    else
                        % adjust counters
                        fprintf(fid, '\\addtocounter{table}{1}\n');
                        fprintf(fid, '\\setcounter{subtable}{0}\n');
                    end
                    fprintf(fid,'\\end{table}\n');
                    
                case 'long_table'
                    %tables in this group
                    eidx = thisgp(strmatch('long_table', imclass(thisgp)));
                    fprintf(fid,'\\begin{table}\n');
                    fprintf(fid,'\\centering\n');
                    for kk=1:length(eidx)
                        fprintf(fid, '\\subtable[%s] {\n', texify(arg.caption{eidx(kk)}));
                        fprintf(fid, '\\resizebox{%1.3f\\textwidth}{!}{\n', imscale);
                        %fprintf(fid, beginTable);
                        tbl = imlist{eidx(kk)};
                        param = fieldnames(tbl);
                        nrow = length(tbl);
                        nf = length(param);
                        s = {'l'};
                        align_str = print_dlm_line2(s(ones(nf, 1)), 'dlm', '|');
                        fprintf(fid, '\\tiny\\begin{tabular}{|%s|}\\hline\n', align_str);
                        % header
                        s = cell(nf, 1);
                        for c = 1:nf
                            if c==nf
                                s{c} = sprintf('\\bf{%s} \\\\', texify(upper(param{c})));
                            else
                                s{c} = sprintf('\\bf{%s}', texify(upper(param{c})));
                            end
                        end
                        print_dlm_line2(s, 'dlm' ,' & ', 'fid', fid);
                        fprintf(fid, '\\hline\n');
                        for r = 1:nrow
                            s = cell(nf, 1);
                            for c=1:nf
                                val = stringify(tbl(r).(param{c}));
                                if iscell(val)
                                    val = print_dlm_line2(val, 'dlm', ':');
                                end
                                val = strtrunc(val, arg.maxstrlen);
                                if c==nf
                                    s{c} = sprintf('%s \\\\', texify(val));
                                else
                                    s{c} = texify(val);
                                end
                            end
                            
                            print_dlm_line2(s, 'dlm' ,' & ', 'fid', fid);
                        end
                        fprintf(fid, '\\hline\n\\end{tabular}}\n');
                        fprintf(fid,'}\n');
                    end
                    % figure caption
                    if arg.showcaption
                        fprintf(fid,'\\caption {%s}\n', texify(arg.groupcaption{ii}));
                    else
                        % adjust counters
                        fprintf(fid, '\\addtocounter{table}{1}\n');
                        fprintf(fid, '\\setcounter{subtable}{0}\n');
                    end
                    fprintf(fid,'\\end{table}\n');
            end
        end % jj
        fprintf(fid,'}\n');
    end % ii
    fprintf(fid,'\\end{document}\n');
    fclose(fid);
    
end
