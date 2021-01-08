function [pp,svdd_test] = eval_svdd_enclosure(test_data,svdd_null,w,perf_obj,cutoff,output_dir,fname)
% Evalutes the SVDD enclosure - algorithm development routine

if nargin < 5
    cutoff = 0.01; 
    mk_plots = 0; 
elseif nargin < 6
    mk_plots = 0; 
else
    mk_plots = 1; 
end

n = size(test_data,1); 
[pp,svdd_test] = chkinput(test_data,svdd_null,w);
poor_samples_ix = find(pp <= cutoff);
remaining_samples_ix = 1:n ; 
remaining_samples_ix(poor_samples_ix) = [];
if ~isempty(poor_samples_ix)
    figure
    ecdf(perf_obj.perf.samplewise.rmse(poor_samples_ix)); 
    hold on ; 
    [f,x] = ecdf(perf_obj.perf.samplewise.rmse(remaining_samples_ix));
    stairs(x,f,'r') ;
    legend(horzcat('bad samples-',num2str(roundn((length(poor_samples_ix)/n)*100,-2)),'%'),...
        horzcat('good samples-',num2str(roundn((length(remaining_samples_ix)/n)*100,-2)),'%'),...
        'Location','SouthEast'); 
    grid on 
    xlabel('x: Median RMSE')
    title('Error Comparison between good/bad samples w/r LM')
    if mk_plots
        orient landscape
        saveas(gcf,fullfile(output_dir,horzcat(fname,'_rmseSVDDsep')),'pdf')
    end
end

[~,farthest_ix] = min(svdd_test) ;
[~,closest_ix] = max(svdd_test) ;
figure
subplot(1,2,1)
hist(perf_obj.perf.samplewise.residual(:,farthest_ix),30)
adj_limits = get(gca,'XLim'); 
title('Farthest Sample')
subplot(1,2,2)
hist(perf_obj.perf.samplewise.residual(:,closest_ix),30)
xlim(adj_limits)
adj_y_limit = get(gca,'YLim'); 
title('Closest Sample')
subplot(1,2,1)
ylim(adj_y_limit); 
if mk_plots
    orient landscape
    saveas(gcf,fullfile(output_dir,horzcat(fname,'_PredErrorComp')),'pdf')
end

figure
ecdf(perf_obj.perf.samplewise.residual(:,farthest_ix))
hold on
[f,x] = ecdf(perf_obj.perf.samplewise.residual(:,closest_ix));
stairs(x,f,'r')
xlim([-3 3])
legend('farthest','closest','Location','NorthWest')
grid on
title('Farthest/Closest Sample Comparison')
xlabel('x : inferred observed difference')
if mk_plots
    orient landscape
    saveas(gcf,fullfile(output_dir,horzcat(fname,'_PredErrorCompEcdf')),'pdf')
end