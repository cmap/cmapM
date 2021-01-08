function mktex(varargin)
% MKTEX A wrapper for compiling inference-observed report
%   MKTEX(varargin) will compile a pdf report by gathering the output from
%   writepanel() and getperf(), write a .tex file, and then compile the
%   .tex file. 
% 
% see also writepanel, getperf
% 
% Author: Brian Geier, Broad 2010

toolName = mfilename ; 
dflt_out = get_lsf_submit_dir ; 
pnames = {'-eda','-vignettes','-perf','-out','-params','-threshold'}; 
 
dflts = {'','','',dflt_out,'',.95};

arg = parse_args(pnames,dflts,varargin{:}); 

print_args(toolName,1,arg); 

otherwkdir = mkworkfolder(arg.out, toolName); 
fprintf('Saving analysis to %s\n',otherwkdir); 
fid = fopen(fullfile(otherwkdir,sprintf('%s_params.txt',toolName)),'wt'); 
print_args(toolName,fid,arg); 
fclose(fid); 

template.line(1).str = '\documentclass{beamer}';
template.line(2).str = '\begin{document}';

box_scale = 0.45; 
% 
fname = pullname(arg.perf); 
fid = fopen(fullfile(arg.out,horzcat(fname,'.tex')),'w'); 
for i = 1 : length(template.line)
    fprintf(fid,'%s\n',template.line(i).str); 
end

%% Build input parameters table
params_obj = parse_params(arg.params); % function call params file
fprintf(fid,'%s\n','\section{Input Params}'); 
fprintf(fid,'%s\n','\frame{');  
fprintf(fid,'%s\n','\begin{table}[ht]');
fprintf(fid,'%s\n','\caption{Input Parameters}');  
fprintf(fid,'%s\n','\centering'); 
fprintf(fid,'%s\n',horzcat('\scalebox{',num2str(0.8),'}{')); 
fprintf(fid,'%s\n','\begin{tabular}{| c | c |}');
fprintf(fid,'%s\n','\hline\hline');
fprintf(fid,'%s\n',...
    'Parameter & Input \\[0.8ex]');
fprintf(fid,'%s\n','\hline'); 
fields = fieldnames(params_obj); 
for i = 1 : length(fields)
    fprintf(fid,'%s&%s\n',insertslash(fields{i}),...
        [insertslash(pullname(eval(['params_obj.',fields{i}]))),' \\']);  
end

fprintf(fid,repmat('%s\n',[1,5]),'[1ex]',...
    '\hline','\end{tabular}}','\end{table}'); 
fprintf(fid,'%s\n','}'); 

%% Build performance summary table 
load(arg.perf) % performance is stored in matlab object

prop.genewise = zeros(1,size(dist.genewise,2)); 
for i = 1 : size(dist.genewise,2)
    p = chi2cdf(dist.genewise(:,i),2);
    prop.genewise(i) = sum(p >= arg.threshhold)/length(p) ;
end

prop.samplewise = zeros(1,size(dist.samplewise,2)); 
for i = 1 : size(dist.samplewise,2)
    p = chi2cdf(dist.samplewise(:,i),2);
    prop.samplewise(i) = sum(p >= arg.threshhold)/length(p) ;
end

resistant.genewise = corr_vals.genewise.spearman.*(1 - prop.genewise) ; 
resistant.samplewise = corr_vals.samplewise.spearman.*(1 - prop.samplewise) ; 

ix = find(arg.perf == '/'); 
% arg.perf(ix(end)+1:find(arg.perf == '.')-1)
fprintf(fid,'%s\n','\section{Measure Summary}'); 
fprintf(fid,'%s\n','\frame{');
fprintf(fid,'%s\n',horzcat('\frametitle{',...
    insertslash(arg.perf(ix(end)+1:find(arg.perf == '.')-1)),'}')); 
fprintf(fid,'%s\n','\begin{table}[ht]');
fprintf(fid,'%s\n','\caption{Correlation Summary}');  
fprintf(fid,'%s\n','\centering'); 
fprintf(fid,'%s\n',horzcat('\scalebox{',num2str(box_scale),'}{')); 
fprintf(fid,'%s\n','\begin{tabular}{| c | c | c | c | c | c | c |}');
fprintf(fid,'%s\n','\hline\hline');
fprintf(fid,'%s\n',...
    'Measure & Sample Pearson & Landmark Pearson & Sample Spearman & Landmark Spearman & Sample Resistant & Landmark Resistant  \\[0.8ex]');
fprintf(fid,'%s\n','\hline'); 

fprintf(fid,'%s&','5\% Quantile'); 
fprintf(fid,'%g&%g&%g&%g&%g&%g',roundn(quantile(corr_vals.samplewise.pearson,.05),-2),...
    roundn(quantile(corr_vals.genewise.pearson,.05),-2),...
    roundn(quantile(corr_vals.samplewise.spearman,.05),-2),...
    roundn(quantile(corr_vals.genewise.spearman,.05),-2),...
    roundn(quantile(resistant.samplewise,.05),-2),...
    roundn(quantile(resistant.genewise,.05),-2));
fprintf(fid,'%s\n%s\n',' \\','\hline');    
fprintf(fid,'%s&','25\% Quantile');   
fprintf(fid,'%g&%g&%g&%g&%g&%g',roundn(perf.samplewise.pearson.quants(1),-2),...
    roundn(perf.genewise.pearson.quants(1),-2),...
    roundn(perf.samplewise.spearman.quants(1),-2),...
    roundn(perf.genewise.spearman.quants(1),-2),...
    roundn(quantile(resistant.samplewise,.25),-2),...
    roundn(quantile(resistant.genewise,.25),-2));
fprintf(fid,'%s\n%s\n',' \\','\hline'); 
fprintf(fid,'%s&','50\% Quantile'); 
fprintf(fid,'%g&%g&%g&%g&%g&%g',roundn(perf.samplewise.pearson.quants(2),-2),...
    roundn(perf.genewise.pearson.quants(2),-2),...
    roundn(perf.samplewise.spearman.quants(2),-2),...
    roundn(perf.genewise.spearman.quants(2),-2),...
    roundn(quantile(resistant.samplewise,.50),-2),...
    roundn(quantile(resistant.genewise,.50),-2));
fprintf(fid,'%s\n%s\n',' \\','\hline'); 
fprintf(fid,'%s&','75\% Quantile'); 
fprintf(fid,'%g&%g&%g&%g&%g&%g',roundn(perf.samplewise.pearson.quants(3),-2),...
    roundn(perf.genewise.pearson.quants(3),-2),...
    roundn(perf.samplewise.spearman.quants(3),-2),...
    roundn(perf.genewise.spearman.quants(3),-2),...
    roundn(quantile(resistant.samplewise,.75),-2),...
    roundn(quantile(resistant.genewise,.75),-2));
fprintf(fid,'%s\n%s\n',' \\','\hline'); fprintf(fid,'%s&','95\% Quantile'); 
fprintf(fid,'%g&%g&%g&%g&%g&%g',roundn(quantile(corr_vals.samplewise.pearson,.95),-2),...
    roundn(quantile(corr_vals.genewise.pearson,.95),-2),...
    roundn(quantile(corr_vals.samplewise.spearman,.95),-2),...
    roundn(quantile(corr_vals.genewise.spearman,.95),-2),...
    roundn(quantile(resistant.samplewise,.95),-2),...
    roundn(quantile(resistant.genewise,.95),-2));
fprintf(fid,'%s\n%s\n',' \\','\hline'); fprintf(fid,'%s&','Mean'); 
fprintf(fid,'%g&%g&%g&%g&%g&%g',roundn(mean(corr_vals.samplewise.pearson),-2),...
    roundn(mean(corr_vals.genewise.pearson),-2),...
    roundn(mean(corr_vals.samplewise.spearman),-2),...
    roundn(mean(corr_vals.genewise.spearman),-2),...
    roundn(mean(resistant.samplewise),-2),...
    roundn(mean(resistant.genewise),-2));
fprintf(fid,'%s\n%s\n',' \\','\hline'); fprintf(fid,'%s&','Variance'); 
fprintf(fid,'%g&%g&%g&%g&%g&%g',roundn(var(corr_vals.samplewise.pearson),-2),...
    roundn(var(corr_vals.genewise.pearson),-2),...
    roundn(var(corr_vals.samplewise.spearman),-2),...
    roundn(var(corr_vals.genewise.spearman),-2),...
    roundn(var(resistant.samplewise),-2),...
    roundn(var(resistant.genewise),-2));
fprintf(fid,'%s\n%s\n',' \\','\hline'); fprintf(fid,'%s&','Range'); 
fprintf(fid,'%g&%g&%g&%g&%g&%g',roundn(range(corr_vals.samplewise.pearson),-2),...
    roundn(range(corr_vals.genewise.pearson),-2),...
    roundn(range(corr_vals.samplewise.spearman),-2),...
    roundn(range(corr_vals.genewise.spearman),-2),...
    roundn(range(resistant.samplewise),-2),...
    roundn(range(resistant.genewise),-2));

% fprintf(fid,'%s\n',' \\');    
fprintf(fid,'%s\n',' \\');    

fprintf(fid,repmat('%s\n',[1,5]),'[1ex]',...
    '\hline','\end{tabular}}','\end{table}'); 

%% Build other measure table, insert in same frame

% fprintf(fid,'%s\n','\section{Global Measure Summary}'); 
fprintf(fid,'%s\n','\begin{table}[hb]');
fprintf(fid,'%s\n',horzcat('\caption{Global Measure Summary}'));  
fprintf(fid,'%s\n','\centering'); 
fprintf(fid,'%s\n',horzcat('\scalebox{',num2str(box_scale),'}{')); 
fprintf(fid,'%s\n','\begin{tabular}{| c | c | c | c | c | c | c | c | c |}');
fprintf(fid,'%s\n','\hline\hline');
fprintf(fid,'%s\n',...
    'Type & 25\% RMSE & Median RMSE & 75\% RMSE &  AUC Spearman & AUC Pearson & AUC Resistant & Median \% Outliers \\[0.8ex]');
fprintf(fid,'%s\n','\hline');


[f,x] = ecdf(resistant.samplewise); 
fprintf(fid,horzcat(repmat('%s&',[1,7]),'%s'), ...
    'sample-wise',num2str(roundn(quantile(perf.samplewise.rmse,.25),-2)),...
    num2str(roundn(quantile(perf.samplewise.rmse,.5),-2)), ...
    num2str(roundn(quantile(perf.samplewise.rmse,.75),-2)),...
    num2str(roundn(perf.samplewise.spearman.auc,-2)),...
    num2str(roundn(perf.samplewise.pearson.auc,-2)),...
    num2str(roundn(AUC(x,f),-2)),...
    num2str(roundn(median(prop.genewise)*100,-2))); 


[f,x] = ecdf(resistant.genewise);
fprintf(fid,'%s\n%s\n',' \\','\hline');
fprintf(fid,horzcat(repmat('%s&',[1,7]),'%s'), ...
    'landmark-wise',num2str(roundn(quantile(perf.genewise.rmse,.25),-2)),...
    num2str(roundn(quantile(perf.genewise.rmse,.5),-2)), ...
    num2str(roundn(quantile(perf.genewise.rmse,.75),-2)),...
    num2str(roundn(perf.genewise.spearman.auc,-2)),...
    num2str(roundn(perf.genewise.pearson.auc,-2)),...
    num2str(roundn(AUC(x,f),-2)),...
    num2str(roundn(median(prop.samplewise)*100,-2))); 
fprintf(fid,'%s\n%s\n',' \\','[1ex]');

fprintf(fid,repmat('%s\n',[1,4]),'\hline',...
    '\end{tabular}}','\end{table}','}');
       
 
       
%% Insert Outlier plots

%genewise

figure, subplot(3,2,1)

plot(prop.genewise-(1-arg.threshhold),corr_vals.genewise.pearson,'.')
hold on ; grid on ; 
plot(prop.genewise-(1-arg.threshhold),corr_vals.genewise.spearman,'r.')
legend('Pearson','Spearman','Location','SouthEast')
xlim([0 1]); ylim([0 1]); 
xlabel('Proportion Outliers'); ylabel('Correlation')
title('Featurewise')

subplot(3,2,[3 4])
grid on ; hold on ; 
% title('Featurewise')
% plot(prop-(1-arg.threshhold),'.')
[f,x] = convkstofreq(prop.genewise-(1-arg.threshhold));
plot(x,f)
% hist(prop-(1-arg.threshhold),30)
% ylabel('Proportion Outliers'); xlabel('Landmark Gene'); 
xlabel('x: proportion outliers'); 
ylabel('proportion of x'); 
% ylim([0 1]); xlim([0 length(prop)]); 

%samplewise

subplot(3,2,2)

plot(prop.samplewise-(1-arg.threshhold),corr_vals.samplewise.pearson,'.')
hold on ; grid on ; 
plot(prop.samplewise-(1-arg.threshhold),corr_vals.samplewise.spearman,'r.')
legend('Pearson','Spearman','Location','SouthEast')
xlim([0 1]); ylim([0 1]); 
xlabel('Proportion Outliers'); ylabel('Correlation')
title('Samplewise')

subplot(3,2,[3 4])
% title('Samplewise')
% plot(prop-(1-arg.threshhold),'r.')
[f,x] = convkstofreq(prop.samplewise-(1-arg.threshhold)); 
plot(x,f,'g')
% hist(prop-(1-arg.threshhold),30)
% ylabel('Proportion Outliers'); xlabel('Sample'); 
% xlabel('x: proportion outliers');
% ylabel('proportion of x'); 
title('Distributional Comparison of Outlier Occurence')
legend('Featurewise','Samplewise','Location','NorthEast'); 
% ylim([0 1]); xlim([0 length(prop)]); 

subplot(3,2,[5 6])
[f,x] = convkstofreq(perf.genewise.rmse); 
plot(x,f); xlabel('x: RMSE'); ylabel('proportion of x')
[f,x] = convkstofreq(perf.samplewise.rmse); 
hold on ; grid on ; plot(x,f,'g'); 
title('Distributional Comparison of RMSE'); 
legend('Featurewise','Samplewise'); 

orient landscape
saveas(gcf,fullfile(arg.out,horzcat(arg.perf(ix(end)+1:find(arg.perf == '.')-1),...
    'outliers_vis.pdf')),'pdf'); 
fprintf(fid,'%s\n','\section{Model Adequacey}') ;
fprintf(fid,'%s\n','\frame{');
fprintf(fid,'%s\n',horzcat('\frametitle{',...
    insertslash(arg.perf(ix(end)+1:find(arg.perf == '.')-1)),'}')); 
    
fprintf(fid,'%s\n',horzcat(...
    '\includegraphics[height=95mm,width=105mm]{',...
    fullfile(arg.out,horzcat(arg.perf(ix(end)+1:find(arg.perf == '.')-1),...
    'outliers_vis.pdf}')))); 
fprintf(fid,'}'); 

%% Insert eda and vignettes

%eda

fprintf(fid,'%s\n','\section{EDA}'); 
fprintf(fid,'%s\n','\frame{'); 
ix = find(arg.eda == '/'); 
fprintf(fid,'%s\n',horzcat('\frametitle{',...
    insertslash(arg.eda(ix(end)+1:find(arg.eda=='.')-1)),'}')); 
fprintf(fid,'%s\n',horzcat(...
    '\includegraphics[height=95mm,width=105mm]{',arg.eda,'}')); 
fprintf(fid,'%s\n','}'); 

%vignettes

fprintf(fid,'%s\n','\section{Vignettes}'); 
fprintf(fid,'%s\n','\frame{'); 
ix = find(arg.vignettes == '/'); 
fprintf(fid,'%s\n',horzcat('\frametitle{',...
    insertslash(arg.vignettes(ix(end)+1:find(arg.vignettes=='.')-1)),'}')); 
fprintf(fid,'%s\n',horzcat(...
    '\includegraphics[height=95mm,width=105mm]{',arg.vignettes,'}')); 
fprintf(fid,'%s\n','}'); 

fprintf(fid,'%s\n','\end{document}'); 
fclose(fid); 

try
    pdflatex(fullfile(arg.out,[fname,'.tex'])); 
    pdflatex(fullfile(arg.out,[fname,'.tex'])); 
    pdflatex(fullfile(arg.out,[fname,'.tex']),'-cleanup',true); 
catch em
    disp(em)
    print_str('Latex compiler not available at command line..') ;
    print_str('Compile manually'); 
end
    
close 

end

function [f,x] = convkstofreq(data)

n = hist(data,30); 
[f,x] = ksdensity(data); 
f = (f/max(f))*(max(n)/length(data)); 

end

function name = insertslash(name)

ix = find(name == '_'); 
for i = 1 : length(ix)
    left = name(1:ix(1)-1); 
    right = name(ix(1)+1:end); 
    name = horzcat(left,'\_',right); 
    ix = find(name == '_'); 
    ix(1:i) = [];
end


end