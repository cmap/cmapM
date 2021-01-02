function create_tex_file(list,varargin)
% TEX   Writes and compiles a foo.tex - summarizing EDA design imagery
%   TEX(list,varargin) will make a foo.tex file given the image locations
%   specified in list. The list structure allows for a nested factor
%   design, which currently is a K factor K-level nested design. The
%   foo.tex file is compiled using the beamer document class. A .pdf file
%   will be created at run-time but may error if pdflatex is not installed
%   at lunix level. 
%   Inputs: 
%       list: a structure object . list.name - factor A name,
%       list.instance.name - factor B nested under A name,
%       list.instance.location - a cell array which specifies the location
%       of the images for factor A (level i), nested factor B (level j)
%       varargin
%           '-out': The output directory, default=pwd
%           '-fname': The fullfile(pathname,filename), i.e. foo_dir/foo.tex 
%   Outputs: 
%       A foo.tex file will be created and compiled in the directory '-out'
%   Warnings:
%       The number of images cannot exceed the tex compiler. An error at 
%       compiling may result if there are too many images. If pdflatex is
%       not installed at system level, then the document can be compiled
%       manuually with TexShop. 
%
%   See also pdflatex
% 
% Author: Brian Geier, Broad 2010

toolName = mfilename ; 

pnames = {'-out','-fname'}; 
dflt_out = get_lsf_submit_dir ; 
dflts = {dflt_out,'tmp'}; 

arg = parse_args(pnames,dflts,varargin{:}); 

print_args(toolName,1,arg); 

template.line(1).str = '\documentclass{beamer}';
template.line(2).str = '\begin{document}';

fid = fopen(fullfile(arg.out,horzcat(arg.fname,'.tex')),'w'); 
for i = 1 : length(template.line)
    fprintf(fid,'%s\n',template.line(i).str); 
end

for i = 1 : length(list)
    fprintf(fid,'%s\n',horzcat('\section{',list(i).name,'}')); 
    for j = 1 : length(list(i).instance)
        sublabel = insertslash(list(i).instance(j).name);
        fprintf(fid,'%s\n',horzcat('\subsection{',sublabel,'}')); 
        for k = 1 : length(list(i).instance(j).location)
            fprintf(fid,'%s\n','\frame{');
            label = list(i).instance(j).location{k} ;
            fprintf(fid,'%s\n',horzcat('\frametitle{',...
                insertslash(pullname(label)),'}')); 
            fprintf(fid,'%s\n',horzcat(...
                '\includegraphics[height=80mm,width=100mm]{',label,'}')); 
            fprintf(fid,'%s\n','}');
        end
    end
end

fprintf(fid,'%s\n','\end{document}'); 
fclose(fid); 

try
    pdflatex(fullfile(arg.out,horzcat(arg.fname,'.tex')));
    pdflatex(fullfile(arg.out,horzcat(arg.fname,'.tex')));
    pdflatex(fullfile(arg.out,horzcat(arg.fname,'.tex')),'-cleanup',1);
catch err
    disp(err)
    fprintf(1,'%s\n','Unable to compile tex source.. try manually');
end