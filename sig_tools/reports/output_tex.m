function output_tex(fname,list)
% fname - output .tex file
% list - structure containing image locations
% THIS IS A SUBROUTINE
% see also writepanel, chkinvariant
fid = fopen(fname,'w');  
fprintf(fid,'%s\n','\documentclass{beamer}'); 
fprintf(fid,'%s\n','\usepackage{beamerthemesplit}'); 
if length(pullname(fname)) > 40
    lab = pullname(fname); 
    
    fprintf(fid,'%s\n',horzcat('\title{',insertslash(lab(1:40)),'\\')); 
    fprintf(fid,'%s\n',horzcat(insertslash(lab(41:end)),'}'));
else

    fprintf(fid,'%s\n',horzcat('\title{',insertslash(pullname(fname)),'}')); 
end

fprintf(fid,'%s\n','\author{CMAP}'); 
fprintf(fid,'%s\n','\date{\today}'); 
fprintf(fid,'%s\n','\begin{document}');
fprintf(fid,'%s\n','\frame{\titlepage}'); 

for i = 1 : length(list)
    fprintf(fid,'%s\n','\frame{');
    fprintf(fid,'%s\n','\begin{center}'); 
    fprintf(fid,'%s\n',horzcat('\includegraphics[height=95mm,width=105mm]{',...
        list(i).fname,'}')); 
    fprintf(fid,'%s\n','\end{center}'); 
    fprintf(fid,'%s\n','}'); 
end

fprintf(fid,'%s\n','\end{document}'); 

fclose(fid); 

clc
close all ; 

end
