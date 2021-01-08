function data = chkinvdist(ge,gn,varargin)
% subroutine called by chkinvariant
% see also chkinvariant

toolName = mfilename ; 
pnames = {'-gmx','-out','-name'};
font_size = 15; 
dflts = {'','/xchip/cogs/devices/data/invset_L10.gmx',pwd};

arg = parse_args(pnames,dflts,varargin{:}); 

print_args(toolName,1,arg); 

invset = parse_gmx(arg.gmx); 
num_levels = length(invset); 

data = struct('invset','');

for i = 1 : num_levels
    data(i).invset = zeros(length(invset(i).entry),size(ge,2)) ; 
    for j = 1 : length(invset(i).entry)
        data(i).invset(j,:) = ge(strcmp(invset(i).entry{j},gn),:);
    end
end

f = zeros(100,num_levels); x = zeros(100,num_levels); 
figure
for i = 1 : num_levels
    [f(:,i),x(:,i)] = ks2freq(data(i).invset(:));
end
plot(x,f,'LineWidth',2)
grid on
title(horzcat(dashit(pullname(arg.name)),' - Invariant Gene Sets'),'FontSize',font_size)
xlabel('X : Expression','FontSize',font_size); ylabel('Proportion of X','FontSize',font_size)
set(gca,'FontSize',font_size)
orient landscape
xlim([3.5 15])
saveas(gcf,fullfile(arg.out,horzcat('invDist_',pullname(arg.name))),'pdf')

figure ; hold on 
colors = mkcolorspec(num_levels); 
for i = 1 : num_levels
    [n,x] = ecdf(data(i).invset(:));
    stairs(x,n,colors{i})
end

title(dashit(pullname(arg.name)),'FontSize',font_size); 
orient landscape
saveas(gcf,fullfile(arg.out,horzcat('invECDF_',pullname(arg.name))),'pdf');
xlim([3.5,15.5]), grid on 
xlabel('x : expression','FontSize',font_size)
ylabel('F(x)','FontSize',font_size); 
set(gca,'FontSize',font_size)


figure ; hold on
for i = 1 : num_levels
    [n,x] = hist(data(i).invset(:),30) ; 
    bar(x,n,1,colors{i})
end

title(dashit(pullname(arg.name)),'FontSize',15);
xlim([3.5,15.5])
xlabel('Expression','FontSize',font_size); 
ylabel('Count','FontSize',font_size); 
set(gca,'FontSize',font_size)
orient landscape
saveas(gcf,fullfile(arg.out,horzcat('invHIST_',pullname(arg.name))),'pdf');
close all 

