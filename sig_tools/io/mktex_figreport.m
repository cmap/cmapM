% MKTEX_FIGREPORT Create LaTeX report file given a list of figures.
%
% MKTEX_FIGREPORT(OFNAME, IMLIST) Creates a TeX file OFNAME given a cell
% array of pathnames to figures IMLIST.
%
% MKTEX_FIGREPORT(OFNAME, IMLIST, 'PARAM1', val1, 'PARAM2', val2, ...) 
% specifies optional parameter name/value pairs.
% '-title'      string. Appends a title to the report.
% '-arg'        structure, such as that returned by GETARGS2. Creates a
%               parameter table
% '-caption'    cell array of the same length as IMLIST. Adds captions for
%               each figure. By default filenames are used as captions.
% '-scale'      float, Scales each figure by scale\textwidth
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
% mktex_figreport('report.tex', {'fig1', 'fig2'}, '-title', 'Report','-caption', {'Figure 1','Figure 2'})
% pdflatex('report.tex','-cleanup', true)
%
% See also PDFLATEX

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

function mktex_figreport(ofname, imlist, varargin)

pnames = {'title', 'arg', 'caption', 'navigation', 'scale','group'};
dflts =  {'', struct([]), {}, false, 1.0, []};
arg = parse_args(pnames, dflts, varargin{:});

nim = length(imlist);
beginTable  = '{\\tiny\\begin{tabular}{|l|p{0.75\\textwidth}|}\\hline\n';
endTable = '\\hline\n\\end{tabular}}\n';
            
if nim
    if ~isempty(arg.caption)
        if ~isequal(length(arg.caption), nim)
            error('Number of captions should equal number of figures');
        end
        docaption = true;        
    else
        % use filenames as captions
        docaption = true;
        
        for ii=1:nim
            [p,f,e] = fileparts(imlist{ii});
            arg.caption{ii} = [f,e];
        end
    end
    
    fid = fopen(ofname, 'wt');
    fprintf(fid, '\\documentclass[10pt]{beamer}\n');   
    fprintf(fid, '\\begin{document}\n');
    if ~arg.navigation
        fprintf(fid, '\\setbeamertemplate{navigation symbols}{}\n');
    end
    % arg structure specified
    if ~isempty(arg.arg)
        fprintf (fid, '\\frame{\n');
        fprintf(fid,'\\begin{center}\n');
        if ~isempty(arg.title)
            fprintf(fid,'%s\\\\\n', texify(arg.title));
        end
        fprintf(fid,'%s\\\\\n', datestr(now));
        fprintf(fid, beginTable);
        param = fieldnames(arg.arg);
        for ii=1:length(param)
            val = stringify(arg.arg.(param{ii}));
            if iscell(val)
                val = print_dlm_line2(val, 'dlm', ',');
            end
            fprintf (fid, '\\emph{%s} & %s\\\\\n', texify(param{ii}), texify(val));
        end
        fprintf(fid, endTable);
        fprintf(fid,'\\end{center}\n');
        fprintf(fid, '}\n');
    else
        fprintf (fid, '\\frame{\n');
        fprintf(fid,'\\begin{center}\n');
        if ~isempty(arg.title)
            fprintf(fid,'%s\\\\\n', texify(arg.title));
        end
        fprintf(fid,'%s\\\\\n', datestr(now));
        fprintf(fid,'\\end{center}\n');
        fprintf(fid, '}\n');
    end
    
    for ii = 1 : nim
        fprintf(fid,'\\frame{\n');        
        fprintf(fid,'\\begin{figure}\n');
        fprintf(fid,'\\centering\n');
        fprintf(fid,'\\includegraphics [width=%1.2f\\textwidth] {%s}\n', arg.scale, imlist{ii});
        if docaption
            fprintf(fid,'\\caption {\\tiny %s}\n', texify(arg.caption{ii}));
        end
        fprintf(fid,'\\end{figure}\n');
        fprintf(fid,'}\n');
    end
    
    fprintf(fid,'\\end{document}\n');
    fclose(fid);

end
