function plot_medianexp(varargin)
% arg.gctfile - specifies the arg.gctfile file, including full path
% gmx - file specifiying expression level grouping, each column corresponds
% to a group, n groupings, with unqueal sample sizes

% dflt_out = get_lsf_submit_dir ; 

toolName = mfilename ; 
pnames = {'-gctfile','-gmxfile','-out'};
ext = mapdir('/Volumes/xchip_cogs');

dflts = {'',fullfile(ext,'geier','invariant_genes_sparc_n37xx_probeid_v3.gmx'),...
    fullfile(ext,'geier/inv_output')};

arg = parse_args(pnames,dflts,varargin{:}); 

print_args(toolName,1,arg); 

%  disp(ext) 
% arg.gctfile,arg.gmxfile,arg.arg.out

ix = find(arg.gctfile == '.'); 
ix2 = find(arg.gctfile == '/'); 
% if nargin == 1
%     arg.gmxfile = '/Users/bgeier/Desktop/invariant_genes_sparc_n37xx_probeid_v3.gmx'; 
%     arg.out = '/Volumes/xchip_cogs/geier/inv_output'; 
%     infgcfList = [];
%      
% end
mkdir(fullfile(arg.out,arg.gctfile(ix2(end)+1:ix-1))); 
arg.out = fullfile(arg.out,arg.gctfile(ix2(end)+1:ix-1)); 
% read in gmx file and get row indices for each group
gmx = parse_gmx(arg.gmxfile); 
num_groups = length(gmx); 
group_labels = cell(1,length(gmx));

[ge,gn,gd,sid] = parse_gct0(arg.gctfile); 
ge = log(double(ge)); 


output.median_vals.bysample = zeros(size(ge,2),num_groups); 
output.median_vals.bygroup = zeros(1,num_groups); 
output.se.bygroup = zeros(1,num_groups); 
xdata = zeros(1,length(gmx)); 
for i = 1 : num_groups
    group_labels{i} = gmx(i).head ; 
    [~,idx] = intersect_ord(gn,gmx(i).entry); 
    xdata(i) = str2double(gmx(i).head(2:end)); 
    data = ge(idx,:); 
    output.median_vals.bysample(:,i) = median(data); 
    output.median_vals.bygroup(i) = exp(median(data(:))); 
    output.se.bygroup(i) = std(bootstrp(1000,@median,exp(data(:)))); 
end

figure
plot(output.median_vals.bysample,'.'); 
xlabel('Sample'); ylabel('Log Median Expression Value')
title('Median Expression for Invariant Gene Sets'); 
legend(group_labels,'Location','NorthEastOutside')
orient landscape; 
saveas(gcf,fullfile(arg.out,'MedianExpFull.pdf'),'pdf')
list(1).fname = fullfile(arg.out,'MedianExpFull.pdf'); 

figure
errorbar(output.median_vals.bygroup,output.se.bygroup)
xlabel('Invariant Gene Group')
ylabel('Median Expression Value')
title('Median Expression within Invariant Gene Group')
set(gca,'XtickLabel',xdata) ; grid on ; orient landscape; 
set(gca,'XTick',1:num_groups)
saveas(gcf,fullfile(arg.out,'MedianExpWitihinInvGroups.pdf'),'pdf')
list(2).fname = fullfile(arg.out,'MedianExpWitihinInvGroups.pdf'); 

figure
imagesc(output.median_vals.bysample), colorbar
title('Log Median Expression Heat Map')
ylabel('Sample'); xlabel('Invariant Gene Group')
set(gca,'XtickLabel',xdata)
set(gca,'XTick',1:num_groups)
orient landscape; 
saveas(gcf,fullfile(arg.out,'MedianExpFulHeatMap.pdf'),'pdf')
list(3).fname = fullfile(arg.out,'MedianExpFulHeatMap.pdf'); 

output_tex(fullfile(arg.out,horzcat(arg.gctfile(ix2(end)+1:ix-1),'_inv_plots.tex')),list)

cd(arg.out); 
system(horzcat('pdflatex ',...
    fullfile(arg.out,horzcat(arg.gctfile(ix2(end)+1:ix-1),'_inv_plots.tex')))); 
close all ; 
end


function output_tex(fname,list)
% fname - output .tex file
% list - structure containing image locations

fid = fopen(fname,'w');  
fprintf(fid,'%s\n','\documentclass{beamer}'); 
fprintf(fid,'%s\n','\begin{document}');

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

end