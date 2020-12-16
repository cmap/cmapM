function ph = hilite_text(th,c)
alpha = 0.4;
n=length(th);
alim=axis;
rect=cell2mat(get(th,'extent'));
left = rect(:,1);
bot = rect(:,2);
right = left+rect(:,3);
top = bot + 0.9*rect(:,4);
ph=zeros(n,1);
for ii=1:n            
    ph(ii) = patch([left(ii),left(ii),right(ii),right(ii)],...
        [bot(ii),top(ii),top(ii),bot(ii)], c, 'facealpha', alpha,'edgecolor','none');
end
axis(alim)
end