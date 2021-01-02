function evalDiff(x,y,axis_labels,varargin)
% EVALDIFF  Evaluates the correspondence between dual tag peak calls
%   evalDiff(x,y,axis_labels,sig_labels,varargin) will evalute the
%   correspondence between dual tag peak calls. The difference is assessed
%   with respect to shape, abosulte residual error, and scale, pearson
%   correlation. If a *.lxb file is supplied then a lxb-reference
%   comparison will be shown for the furhtest and closest peak calls. For
%   example, if y is a control set of peak calls then the furthest/closest
%   comparisons will indicate prediction change when using the method which
%   produced x . In the lxb-reference plot, the peak calls are overlayed on
%   the signal histogram. 
%   Inputs: 
%       x - a 500 by 2 matrix of peak calls for the 500 analytes. Each
%       column corresponds to a call within that distribution. The first
%       column is the major component (i.e. the larger support) and the
%       second column is the minor component. NOTE: The lxb file supplied
%       is the bimodal distribution where x's peak calls are derived. 
%       y - a 500 by 2 matrix of peak calls for the 500 analytes. The rows
%       and columns of y are consistent with x. NOTE: The columns of y can
%       be uni-tag calls from different lxb files. 
%       axis_labels - a two element cell array which specifies the names of
%       x and y, e.g. {'GMM','Uni'}, which would indicate that x was found
%       using a gaussian mixture model and y was found via separate
%       uni-tag. 
%       varargin: 
%           '-out' - The output directory
%           '-fname' - The file name, which is appended to each plot type
%           '-lxb_file' - The *.lxb file for lxb-reference comparison
%   Outputs: 
%       Five figures are saved to the output directory work folder, which
%       is created at run-time. An overall comparison plot shows the shape
%       and scale changes/differences between the calls in x and y. If a
%       *.lxb files is supplied then the furthest/closest of major/minor
%       component peak calls are shown with respect to the bimodal luminex
%       signal distribution. 
% 
% Author: Brian Geier, Broad 2010

spopen ; 

if ~exist('axis_labels','var')
    error('axis_labels must be specified!')
end

if ( size(x,1) ~= size(y,1) ) || ( size(x,2) ~= size(y,2) )
    error('x and y matrices are not consistent')
end

dflt_out = pwd ; 
toolName = mfilename ; 
pnames = {'-out','-fname','-lxb_file'}; 
dflts = {dflt_out,'',''}; 
arg = parse_args(pnames,dflts,varargin{:}); 
print_args(toolName,1,arg); 
otherwkdir = mkworkfolder(arg.out, toolName); 
fprintf('Saving analysis to %s\n',otherwkdir); 
fid = fopen(fullfile(otherwkdir,sprintf('%s_params.txt',toolName)),'wt'); 
print_args(toolName,fid,arg); 
fclose(fid); 

if ~isempty(arg.lxb_file)
    lxb = parse_lxb(arg.lxb_file); 
else
    lxb = [];
end

startPlot = findNewHandle; 

evalDiff_plots(x,y,axis_labels,lxb);

for i = startPlot : max(get(0,'children'))
    figure(i)
    orient landscape
    saveas(i,fullfile(otherwkdir,horzcat(get(i,'Name'),'_',arg.fname)),'pdf'); 
end

end

function evalDiff_plots(x,y,axis_labels,lxb)
% Plotting routine for evalDiff() 

sig_labels = {'Major','Minor'}; 

ci = zeros(2,size(x,2));
for i = 1 : size(x,2)
    ci(:,i) = bootci(3000,{@corr,x(:,i),y(:,i)});
end

figure
subplot(321)
plot(x(:,1),y(:,1),'.'), lsline
grid on ; 
xlabel(axis_labels{1})%,'FontSize',12); 
ylabel(axis_labels{2})%,'FontSize',12)
title(horzcat(sig_labels{1}, ' Comparison'))
legend(horzcat('ci = (',num2str(ci(1,1)),',',...
        num2str(ci(2,1)),'), Rho=',num2str(corr(x(:,1),y(:,1)))),'Location','NorthWest')
    
subplot(322)
plot(x(:,2),y(:,2),'.'), lsline
grid on ; 
xlabel(axis_labels{1})%,'FontSize',12); 
ylabel(axis_labels{2})%,'FontSize',12)
title(horzcat(sig_labels{2}, ' Comparison'))
legend(horzcat('ci = (',num2str(ci(1,2)),',',...
        num2str(ci(2,2)),'), Rho=',num2str(corr(x(:,2),y(:,2)))),'Location','NorthWest')

e = x - y; 
subplot(3,2,[3 4]), hold on 
c = 'rg';

h_legend = cell(length(sig_labels),1);
for i = 1 : size(x,2)
    [f,dx] = ecdf(abs(e(:,i))); 
    stairs(dx,f,c(i))
    h_legend{i} = horzcat(sig_labels{i},' E(x)=',num2str(mkrec(abs(e(:,i)),'show',0)));
end
ylabel('F(x)')
xlabel('x : Absolute Deviation'), grid on 
legend(h_legend,'Location','SouthEast')

sort_e = sort(abs(e),'descend'); 
subplot(3,2,[5 6]), plot(sort_e)
ylabel('Absolute Deviation'), xlabel('Sorted by Magnitude')
grid on
legend(sig_labels)
set(gcf,'Name','OverallComparison')

if ~isempty(lxb)
    %% LXB Reference Plots
    %   Major Component Comparison
    figure

    [~,ix] = sort(abs(e(:,1)),'descend'); 

    for i = 1 : 25
        subplot(5,5,i)
        hist(lxb.RP1(lxb.RID==ix(i)),30)
        hold on ; 
        plot(x(ix(i),1),25,'r.')
        plot(y(ix(i),1),35,'g.')
        plot(x(ix(i),2),25,'r*')
        plot(y(ix(i),2),35,'g*')

        ylim([0 40])
        set(gca,'YTick',[],'FontSize',7)
        h = legend(horzcat('Signal-',num2str(ix(i))),axis_labels{1},axis_labels{2},'Location',...
            'SouthOutside');
        set(h,'FontSize',6,'box','off','Interpreter','none');
    end
    set(gcf,'Name','MajorFurthestComparsion')

    figure
    for i = 1 : 25
        subplot(5,5,i)
        hist(lxb.RP1(lxb.RID==ix(end-(i-1))),30)
        hold on ; 
        plot(x(ix(end-(i-1)),1),25,'r.')
        plot(y(ix(end-(i-1)),1),35,'g.')
        plot(x(ix(end-(i-1)),2),25,'r*')
        plot(y(ix(end-(i-1)),2),35,'g*')

        ylim([0 40])
        set(gca,'YTick',[],'FontSize',7)
        h = legend(horzcat('Signal-',num2str(ix(end-(i-1)))),axis_labels{1},axis_labels{2},'Location',...
            'SouthOutside');
        set(h,'FontSize',6,'box','off','Interpreter','none');
    end
    set(gcf,'Name','MajorClosestComparison')


    %   Minor Component Comparison
    [~,ix] = sort(abs(e(:,2)),'descend'); 

    figure
    for i = 1 : 25
        subplot(5,5,i)
        hist(lxb.RP1(lxb.RID==ix(i)),30)
        hold on ; 
        plot(x(ix(i),1),25,'r.')
        plot(y(ix(i),1),35,'g.')
        plot(x(ix(i),2),25,'r*')
        plot(y(ix(i),2),35,'g*')

        ylim([0 40])
        set(gca,'YTick',[],'FontSize',7)
        h = legend(horzcat('Signal-',num2str(ix(i))),axis_labels{1},axis_labels{2},'Location',...
            'SouthOutside');
        set(h,'FontSize',6,'box','off','Interpreter','none');
    end
    set(gcf,'Name','MinorFurthestComparison')

    figure
    for i = 1 : 25
        subplot(5,5,i)
        hist(lxb.RP1(lxb.RID==ix(end-(i-1))),30)
        hold on ; 
        plot(x(ix(end-(i-1)),1),25,'r.')
        plot(y(ix(end-(i-1)),1),35,'g.')
        plot(x(ix(end-(i-1)),2),25,'r*')
        plot(y(ix(end-(i-1)),2),35,'g*')

        ylim([0 40])
        set(gca,'YTick',[],'FontSize',7)
        h = legend(horzcat('Signal-',num2str(ix(end-(i-1)))),axis_labels{1},axis_labels{2},'Location',...
            'SouthOutside');
        set(h,'FontSize',6,'box','off','Interpreter','none');
    end
    set(gcf,'Name','MinorClosestComparison')
end

end
