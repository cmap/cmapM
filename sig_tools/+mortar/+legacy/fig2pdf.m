%Generates a LaTeX report of exported figures

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

%Changes: 9/20/2004,RN fixed 'too many unprocessed floats' error

function fig2pdf(imgfnames, outfile)

%TeX strings

beginMain = '\\documentclass{article}\n\\usepackage{graphicx}\n';
% preambleMain = '\\title{}\n\\author{}\n\\date{}\n';
% bodyMain  = '\\begin{document}\n\\pagestyle{empty}\n\\maketitle\n';
bodyMain  = '\\begin{document}\n\\pagestyle{empty}\n';

%includeMain = '\\include{%s}\n';
endMain = '\\end{document}';


beginFig = '\\begin{figure}\n\\centering\n';
bodyFig = '\\includegraphics[width=\\textwidth]{%s}\n';
endFig = '\\end{figure}\n\n';
clearPage = '\\clearpage\n\n';

%beginTable  = '\\begin{tabular}{|l|l|}\\hline\n';
%endTable = '\\hline\n\\end{tabular}\n';

if all(isfileexist(imgfnames))

    [p,f,e]=fileparts(outfile);
    mainfile = sprintf('%s.tex',f);
    
    fid=fopen(mainfile, 'wt');
    fprintf(fid, beginMain);
    % fprintf(fid, preambleMain);
    fprintf (fid, bodyMain);
    
    nfig = length(imgfnames);
    
    for ii=1:nfig
        
        fprintf(fid, beginFig);
        fprintf(fid, bodyFig, imgfnames{ii});
        fprintf(fid, endFig);
        if isequal(mod(ii-1, 4)+1, 4)
            fprintf(fid, clearPage);
        end
    end
    
    fprintf (fid,endMain);
    fclose (fid);

end

