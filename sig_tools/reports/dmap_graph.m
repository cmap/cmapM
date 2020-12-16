function [bg,g] = dmap_graph(foldchange,ref_gene,ref_lineage)
% foldchange.state , foldchange.val
% Build Reference graph for dmap data set
% See Rajiv Narayan for a better implementation

population_states = {'HSC1','HSC3','CMP','MEP','ERY1',...
    'ERY2','ERY3','ERY4','ERY5','MEGA1','MEGA2','GMP',...
    'GRAN1','GRAN2','GRAN3','MONO1','MONO2','EOS2','BASO1',...
    'DENDA1','DENDA2','TLP','PRE_BCELL2','PRE_BCELL3',...
    'BCELLA1','BCELLA2','BCELLA3','BCELLA4','PRO_NK','NKA1',...
    'NKA2','NKA3','NKA4','PRO_TC','TCELLA6','TCELLA7','TCELLA8',...
    'TCELLA1','TCELLA2','TCELLA3','TCELLA4'}; 
if nargin == 0 % debugging
    foldchange.state = population_states ;
    foldchange.val = rand(length(population_states),1).*(4-0) + 0 ;
end
cm = mksparsemat ; 
bg = biograph(cm,population_states) ; 
set(bg,'LayoutType','radial') ; 
set(bg,'ShowArrows','off','Scale',0.5);
set(bg,'NodeAutoSize','off'); 
for i = 1 : length(bg.Nodes) 
    bg.Nodes(i).Shape = 'circle'; 
    bg.Nodes(i).FontSize = 15 ; 
    ix = strcmp(bg.Nodes(i).ID,foldchange.state); 
    if sum(ix) == 0 
        continue
    end
    bg.Nodes(i).Size = repmat(max(round(abs(foldchange.val(ix))*3),3),[1,2]); 
    if foldchange.val(ix) > 0 
        bg.Nodes(i).Color = [255,48,48]./255;%[1,0,0]; 
    elseif foldchange.val(ix) < 0 
        bg.Nodes(i).Color = [30,144,255]./255; %[0,0,1]; 
    end
end

% Transfer biograph to a figure
% set name property 
g = biograph.bggui(bg);
% set(g.biograph.hgAxes,'DataAspectRatio',[266.4565  238.0000    1.0000],...
%     'OuterPosition',[-60.8400  -52.3600  929.3000  824.0600],...
%     'Position',[ 0     0   824   736]);

f = figure() ;
set(f,'position',[684   452   601   601]);
copyobj(g.biograph.hgAxes,f);

set(f,'units','points',...'position',[684   452   601   601],...
    'Name',[ref_gene,'_',ref_lineage]); %,'Position',[668   476   589   603])
set(f,'PaperPositionMode','auto','Color',[1,1,1]);
text(2,2,[dashit(ref_gene),' ',dashit(ref_lineage)],'FontSize',16); 
end

function cm = mksparsemat
% sparse connection matrix
cm = zeros(41) ; 

cm(1,1:2) = [0,1]; 
cm(3,12) = 1; %main connection
cm(2,22) = 1; %main connection
% cm(2:8,3:9) = 1; % first branch
cm(2,3) = 1; 
cm(3,4) = 1; 
cm(4,5) = 1; 
cm(5,6) = 1; 
cm(6,7) = 1; 
cm(7,8) = 1; 
cm(8,9) = 1; 
cm(4,10) = 1; 
cm(10,11) = 1; 
cm(12,13) = 1; 
cm(13,14) = 1; 
cm(14,15) = 1; 
cm(12,16) = 1; 
cm(16,17) = 1; 
cm(12,18:20) = 1; 
cm(20,21) = 1; 
cm(22,23) = 1; 
cm(23,24) = 1; 
cm(24,25) = 1 ; 
cm(25,26) = 1; 
cm(26,27) = 1; 
cm(26,27) = 1; 
cm(27,28) = 1; 
cm(22,29) = 1; 
cm(29,30) = 1; 
cm(30,31) = 1; 
cm(31,32) = 1 ;
cm(32,33) = 1; 
cm(22,34) = 1; 
cm(34,35) = 1; 
cm(35,36) = 1; 
cm(36,37) = 1; 
cm(34,38) = 1; 
cm(38,39) = 1; 
cm(39,40) = 1; 
cm(40,41) = 1; 

end       