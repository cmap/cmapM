function summarize_gct(varargin)
% SUMMARIZE_GCT     Write a basic EDA report
%   summarize_gct(varargin) will write a report summarizing dataset
%   statistics. 
%   Inputs: 
%       '-obs': The dataset, gct
%       '-out': The output dir, dfeault is submission dir
%       '-cls': A classification file, cls, optional. Will append labels to
%       plots
%       '-dep': The feature space to explore, grp, optional. If not
%       specified, then all features will be used
%   Outputs: 
%       Vignettes summarizing dispersion, sample to sample variability.
%       Images are compiled into a single report via LaTex. 
% 
% see also pdflatex
% 
% Author: Brian Geier, Broad 2010

dflt_out  = get_lsf_submit_dir ; 

toolName = mfilename ; 
pnames = {'-obs','-out','-cls','-dep'};
dflts = {'',dflt_out,'',''};

arg = parse_args(pnames,dflts,varargin{:});

print_args(toolName,1,arg); 
otherwkdir = mkworkfolder(arg.out,toolName); 
fprintf('Saving analysis to %s\n',otherwkdir); 
fid = fopen(fullfile(otherwkdir,sprintf('%s_params.txt',toolName)),'wt'); 
print_args(toolName,fid,arg); 
fclose(fid); 

if ~isempty(arg.cls)
    cl = parse_cls(arg.cls); 
end
[ge,gn,~,sid] = parse_gct0(arg.obs); 
if ~isempty(arg.dep)
    [~,keep] = intersect_ord(gn,parse_grp(arg.dep)); 
    ge = ge(keep,:);  
end
[p,n] = size(ge); 
fprintf(1,'%s\n',horzcat('Number samples: ',num2str(n))); 
fprintf(1,'%s\n',horzcat('Number features: ',num2str(p))); 

start_plot = findNewHandle ; 
figure
if n <= 75 
    boxplot(ge,'orientation','vertical','labelorientation','inline',...
        'labels',sid)
    if ~isempty(arg.cls)
        append_sid_cls(cl,gcf,'x_axis'); 
    else
        set(gca,'XTick',sid); 
        rotateticklabel(gca);
    end
elseif n <= 200
    boxplot(ge,'plotstyle','compact','orientation','vertical',...
        'labelorientation','inline','labels',sid)
else
%     plot([max(ge) ; quantile(ge,.75);  ...
%         median(ge) ; quantile(ge,.25) ; min(ge) ]' )
    quants = [.01,.05:.10:.95,.99] ;
    plot(quantile(ge,quants)')
    l_h = cell(length(quants),1); 
    
    xlim([0,size(ge,2)])
    if ~isempty(arg.cls)
        append_cluster_membership(grp2idx(cl),gcf,'x_axis'); 
    end
    for i = 1 :length(l_h)
        l_h{i} = num2str(quants(i)) ; 
    end
    set(gca,'XTickLabel','')
    xlabel('Sample'); ylabel('Expression')
    h = legend(l_h,'Location','EastOutside'); 
    title(horzcat('Sample Quantile Change - ',dashit(pullname(arg.obs)))); 
    set(h,'FontSize',12); 
end
set(gcf,'Name','sample_summary'); 

figure
plot(mean(ge,2),cv(ge),'.','MarkerSize',15)
set(gcf,'Name','mean_cv'); 
grid on  ; ylabel('Samplewise CV')
xlabel('Samplewise Mean')
title(dashit(pullname(arg.obs)))


figure
hist(ge(:),30)
set(gcf,'Name','hist'); 
xlabel('Expression Values')
ylabel('Count')

title(dashit(pullname(arg.obs)))


for i = start_plot : max(get(0,'children'))
    figure(i)
    orient landscape
    saveas(i,fullfile(otherwkdir,horzcat(pullname(arg.obs),'_',get(i,'Name'))),...
        'pdf'); 
end

fid = fopen(fullfile(otherwkdir,horzcat(pullname(arg.obs),'_EDA.tex')),'w'); 
fprintf(fid,'%s\n','\documentclass{beamer}'); 
fprintf(fid,'%s\n','\usepackage{beamerthemesplit}'); 
fprintf(fid,'%s\n','\title{summarize\_gct call for \\'); 
fprintf(fid,'%s\n',horzcat(insertslash(pullname(arg.obs)),'}')); 
fprintf(fid,'%s\n','\author{CMAP}'); 
fprintf(fid,'%s\n','\date{\today}'); 

fprintf(fid,'%s\n','\begin{document}'); 

fprintf(fid,'%s\n','\frame{\titlepage}'); 
fprintf(fid,'%s\n','\section[Outline]{}'); 

fprintf(fid,'%s\n','\frame{\tableofcontents}'); 
fprintf(fid,'%s\n','\section{Plots}'); 
fprintf(fid,'%s\n','\subsection{Sample Summary}'); 
% PLOT ORDERS
% 1 : sample_summary
% 2 : mean_cv
% 3 : hist
% 4 : pca_view
fprintf(fid,'%s\n','\frame{'); 
fprintf(fid,'%s\n',horzcat('\frametitle{',insertslash(pullname(arg.obs)),'}')); 
fprintf(fid,'%s\n','\begin{figure}') ;
fprintf(fid,'%s\n','\begin{tabular} {c c}'); 
fprintf(fid,'%s\n','\begin{minipage}[b]{0.5\linewidth}'); 
fprintf(fid,'%s\n','\centering'); 
fprintf(fid,'%s\n',horzcat('\includegraphics[height=60mm,width=60mm]{',...
    fullfile(otherwkdir,horzcat(pullname(arg.obs),'_',get(start_plot,'Name'),'.pdf')),'}')) ;   
fprintf(fid,'%s\n','\caption{Sample Spread}'); 
fprintf(fid,'%s\n','\end{minipage}'); 
fprintf(fid,'\n\n'); 
fprintf(fid,'%s\n','\begin{minipage}[b]{0.5\linewidth}'); 
fprintf(fid,'%s\n','\centering'); 
fprintf(fid,'%s\n',horzcat('\includegraphics[height=60mm,width=60mm]{',...
    fullfile(otherwkdir,horzcat(pullname(arg.obs),'_',get(start_plot+2,'Name'),'.pdf')),'}')) ;   
fprintf(fid,'%s\n','\caption{Expression Histogram}'); 
fprintf(fid,'%s\n','\end{minipage}'); 
fprintf(fid,'%s\n','\end{tabular}'); 
fprintf(fid,'%s\n','\end{figure}'); 
fprintf(fid,'%s\n','}'); 
% look = {'Mean vs. CV','PCA Serpataion'}; 

for i = start_plot : max(get(0,'children'))
%     fprintf(fid,'%s\n',horzcat('\subsection{',get(i,'Name'),'}')); 
    fprintf(fid,'%s\n','\frame{');
    fprintf(fid,'%s\n',horzcat('\frametitle{',insertslash(pullname(arg.obs)),'}')); 
    fprintf(fid,'%s\n',horzcat('\includegraphics[height=75mm,width=120mm]{',...
        fullfile(otherwkdir,horzcat(pullname(arg.obs),'_',...
        get(i,'Name'),'.pdf')),'}')) ;   
    fprintf(fid,'%s\n','}'); 
    fprintf(fid,'\n'); 
end

fprintf(fid,'%s\n','\end{document}') ;

fclose(fid); 

try 
    pdflatex(fullfile(otherwkdir,horzcat(pullname(arg.obs),'_EDA.tex'))); 
    % Run again to get bookmarks/toc
    pdflatex(fullfile(otherwkdir,horzcat(pullname(arg.obs),'_EDA.tex'))); 
    pdflatex(fullfile(otherwkdir,horzcat(pullname(arg.obs),'_EDA.tex')),'-cleanup',1); 
    system(horzcat('cp ',fullfile(otherwkdir,horzcat(pullname(arg.obs),'_EDA.pdf')),...
        ' ',arg.out)); 
catch em
    disp(em)
end
clc
close all 