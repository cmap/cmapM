% PLOT_HEADER color coded class header bars
%   EDG = PLOT_HEADER(CL,CN,NL,H)

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

%   TODO: plot multiple bars

function edg = plot_header(cl,cn,nl,h)

axis(h);

% nsample = length(nl);
nclass = length(cn);
nbars = size(nl,2);
% 
% edg = mod(find(diff(nl))-1,nsample)+1;
[edg,v] = class_edg(nl);

if isequal(nbars,1)
    %to fix quirk in matlab which refuses to plot single stacked bars
    bh = barh([v nan(size(v))]',1,'stacked');
    axis tight
    set(gca,'xtick',[],'ytick',[],'ylim',[0.6,1.4]);

    for ii=1:nclass
        cmenu(ii)=uicontextmenu;
        set(bh(ii),'uicontextmenu',cmenu(ii));
        item(ii)=uimenu(cmenu(ii),'label',cn{ii});        
    end
else
    
    bh = barh(v,1,'stacked');
    axis tight
    
end



%sample labels
% text((0:nsample-1)+0.5,ones(nsample,1)*0.65,cl,'rotation',90,'color','c','fontweight','bold','fontsize',10,'horizontalalignment','left');

%class labels
% text([0;edg] + v*0.5, ones(nclass,1),cn,'color','y','fontweight','bold','fontsize',14,'horizontalalignment','center');

%rotated class labels

text([0;edg(1:end-1)] + v*0.5, ones(nclass,1)*0.65,texify(cn),'rotation',90,'color','b','fontweight','bold','fontsize',10,'horizontalalignment','left');

%  colormap cool
