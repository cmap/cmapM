function chksvdd(svdd_null,svdd_test,perf_obj,quants,out,fname)
% algorithm development rountine

if nargin < 4
    quants =  [0.001,0.01,0.05,0.15,0.25,0.5,0.75] ; 
    mk_plots = 0; 
    fname = '';
elseif nargin < 5
    mk_plots = 0 ; 
    fname = '';
else
    mk_plots = 1; 
end


idx = iquantile(svdd_test,quants) ; % sample ids

figure ; hold on 
c = 'rgbmy' ; 
d = min(5,length(quants)); 
h_legend = cell(d,1);
for i = 1 : d
    [f,x] = ecdf(abs(perf_obj.perf.samplewise.residual(:,idx(i)))); 
    stairs(x,f,c(i))
    h_legend{i} = num2str(quants(i)); 
end
grid on  ;
xlim([0 3])
xlabel('x : Abs Diff')
ylabel('F(x)')
title(horzcat('Error Dist Comp wrt SVDD quantile - ',dashit(fname)))

legend(h_legend,'Location','SouthEast') 
if mk_plots
    orient landscape
    saveas(gcf,fullfile(out,horzcat(dashit(fname),'_erDistWrtSVDDquant-int')),'pdf')
end

figure
plot(perf_obj.perf.samplewise.rmse,svdd_test,'.')
xlabel('RMSE')
ylabel('SVDD statistic')
grid on 
title(dashit(fname))
if mk_plots
    orient landscape
    saveas(gcf,fullfile(out,horzcat(dashit(fname),'_obsSVDDwrtRMSE')),'pdf')
end

% figure
% plot(var(perf_obj.perf.samplewise.residual),svdd_test,'.')
% xlabel('Prediction Variation')
% ylabel('SVDD statistic')
% grid on 
% title(dashit(fname))
% if mk_plots
%     orient landscape
%     saveas(gcf,fullfile(out,horzcat(dashit(fname),'_obsSVDDwrtPV')),'pdf')
% end


cutoffs = quantile(svdd_null,quants); 
figure ; hold on ; 
show = 1: d; 
for i = 1 : d
    t = perf_obj.perf.samplewise.residual(:,svdd_test <= cutoffs(i)); 
    if isempty(t) 
        show(i) = [];
        continue
    end
    [f,x] = ecdf(abs(t(:))); 
    stairs(x,f,c(i))
end
grid on ; 
xlim([0 3])

xlabel('x : Abs Diff')
ylabel('F(x)')
title(horzcat('Error Dist Comp wrt SVDD NULL quantile - ',dashit(fname)))
legend(h_legend(show),'Location','SouthEast') 
if mk_plots
    orient landscape
    saveas(gcf,fullfile(out,horzcat(dashit(fname),'_erDistWrtSVDDquant-ext')),'pdf')
end

figure
cutoff = quantile(svdd_null,.05); 
ix = [find(svdd_test <= cutoff), find(svdd_test > 0.25)];
[~,ix_s] = sort(svdd_test); 
if length(svdd_test) < 50 
    
    boxplot(abs(perf_obj.perf.samplewise.residual(:,ix)),'plotstyle','compact')
    xlabel('Residuals within a sample'); 
    ylabel('Absolute Difference bw inf/obs')
    set(gca,'XTickLabel',{''}); 
    set(gca,'XTickLabel',1:sum(svdd_test <= cutoff)); 
    title(horzcat(dashit(fname),' - marked bad samples detected at 0.01'))
    if mk_plots
        orient landscape
        saveas(gcf,fullfile(out,horzcat(dashit(fname),'_boxplot_view')),'pdf')
    end
else
    y = abs(perf_obj.perf.samplewise.residual(:,ix_s)) ; 
%     a = [ min(y); quantile(y,.25) ; ...
%         median(y) ; quantile(y,.75) ; max(y) ]' ; 
%     a = quantile(y,[0.01,0.15,0.25,0.5,0.65,0.75,0.99])'; 
    a = quantile(y,[0.75,0.85,0.95,0.99,0.999])'; 
    for i = 1 : 5
        a(:,i) = smooth(a(:,i),15); 
    end
%     a = quantile(y,0.7:0.01:0.99)'; 
    plot(a)
    legend('75%','85%','95%','99%','+99%')
    xlabel('Residuals within a sample'); 
    ylabel('Absolute Difference bw inf/obs')
    title(horzcat(dashit(fname),'-Smoothed Quantiles, sorted by svdd statistic'))
    set(gca,'XTick',1:sum(svdd_test <= cutoff)); 
    set(gca,'XTickLabel',1:sum(svdd_test <= cutoff)); 
%     title(horzcat(dashit(fname),' - marked bad samples detected at 0.01'))
end

if mk_plots
    orient landscape
    saveas(gcf,fullfile(out,horzcat(dashit(fname),'_smoothedQuantiles')),'pdf')
end


figure
hold on
plot(quantile(abs(perf_obj.perf.samplewise.residual),.75),svdd_test,'.')
plot(quantile(abs(perf_obj.perf.samplewise.residual),.85),svdd_test,'r.')
plot(quantile(abs(perf_obj.perf.samplewise.residual),.95),svdd_test,'g.')
legend('75%','85%','95%')
xlabel('Residual Error Quantile')
ylabel('SVDD Statistic')
title(dashit(fname))
grid on 

if mk_plots
    orient landscape
    saveas(gcf,fullfile(out,horzcat(dashit(fname),'_quantileSpreadwSVDD')),'pdf')
end

