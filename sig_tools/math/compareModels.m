function results = compareModels(modelA,modelB,varargin)
% compareModels     Runs a comparison between modelA and modelB
%   compareModels(modelA,modelB,arg.fid,arg.show) will test which model is
%   better with respect to accuracy and shape. A chi squared test is
%   performed between the model errors and the predicted/observed
%   correlations. The chi squared test is used when comparing two discrete
%   distributions. 
%   Inputs: 
%       modelA,modelB : the lsa performance object file name, *.mat
%       varargin:
%           'show' : a logical indicator for plotting, default = 1
%           'fid' : a file identifier for writing log, default = 1, i.e.
%           print to the command line
%   Outputs: 
%       An ECDF plot of the expected errors and spearman correlation are
%       outputted in new figures. 
%       results : a data structure with the following fieldnames
%           'aoc' : the area above the error ecdf for each dependent gene
%           model, which is equivalent to the expectation of the error
%           'auc' : the area under the spearman correlation ecdf
%           'corrA','corrB' : The ecdf estimation for the correlation vector found
%           given modelA and modelB. i.e. [f,x] = ecdf(y); 
% 
% Author: Brian Geier, Broad 2010

pnames = {'show','fid'}; 

dflts = {1,1}; 

arg = parse_args(pnames,dflts,varargin{:}); 

%load perf object
fprintf(arg.fid,'\n'); 
fprintf(arg.fid,'%s\n\n','Starting Run'); 
a = load(modelA) ;
b = load(modelB) ;
fprintf(arg.fid,'%s\n',horzcat('Model A : ',modelA)); 
fprintf(arg.fid,'%s\n',horzcat('Model B : ',modelB)); 

fprintf(arg.fid,'%s\n','Data Successfully Loaded');

[p,stat] = chitest(a.corr_vals.genewise.spearman,...
    b.corr_vals.genewise.spearman); 
fprintf(arg.fid,'%s\t%s\n',horzcat('Shape : Test Statistic = ',num2str(stat)),...
    horzcat('p = ',num2str(p))); 

aocA = mkrec(a.perf.genewise.residual,'arg.show',0); 
aocB = mkrec(b.perf.genewise.residual,'arg.show',0); 

[fa_aoc,xa_aoc] = ecdf(aocA); 
[fb_aoc,xb_aoc] = ecdf(aocB); 
[fa_corr,xa_corr] = ecdf(a.corr_vals.genewise.spearman); 
[fb_corr,xb_corr] = ecdf(b.corr_vals.genewise.spearman); 
if arg.show
    figure
    hold on ; grid on ; 
    stairs(xa_aoc,fa_aoc)
    stairs(xb_aoc,fb_aoc,'r')
    legend('Model A', 'Model B')
    xlabel('x: Expected Errors','FontSize',16)
    ylabel('F(x)','FontSize',16)
    set(gca,'FontSize',16,'YTick',0:0.1:1)

    figure
    hold on ; grid on ; 
    stairs(xa_corr,fa_corr)
    stairs(xb_corr,fb_corr,'r')
    legend('Model A', 'Model B','Location','NorthWest')
    xlabel('x: Spearman Correlations','FontSize',16)
    ylabel('F(x)','FontSize',16)
    set(gca,'FontSize',16,'YTick',0:0.1:1)
end
aucA = AUC(xa_corr,fa_corr); 
aucB = AUC(xb_corr,fb_corr); 

if p < 0.05
    fprintf(arg.fid,'%s\n','Models have significantlly different shape performance'); 
    if aucA < aucB
        fprintf(arg.fid,'%s\n','Model A has best shape performance'); 
    else
        fprintf(arg.fid,'%s\n','Model B has best shape performance');
    end
    [p,stat] = chitest(aocA,aocB) ;
    fprintf(arg.fid,'%s\t%s\n',horzcat('Accuracy : Test Statistic = ',num2str(stat)),...
        horzcat('p = ',num2str(p))); 
    if p < 0.05
        
        if aucA < aucB
            fprintf(arg.fid,'%s\n','Model A is the winner!'); 
        else 
            fprintf(arg.fid,'%s\n','Model B is the winner!'); 
        end

    else
        fprintf(arg.fid,'%s\n','Shape is different but accuracy is equivalent') ;
    end
end

results.aoc = [aocA(:) aocB(:)]; 
results.auc = [aucA aucB]; 
results.corrA = [fa_corr(:),xa_corr(:)]; 
results.corrB = [fb_corr(:),xb_corr(:)]; 
fclose(arg.fid);  
