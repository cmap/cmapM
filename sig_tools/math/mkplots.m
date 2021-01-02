function [dist,pct,pts] = mkplots(seqA,seqB)
% subroutine

figure

dist = zeros(1,500) ;
pct = zeros(size(dist)) ;
for i = 1 : 500
    dist(i) = norm(seqA(:,i) - seqB(:,i)) ;
    pct(i) = matchpct(seqA(:,i),seqB(:,i)); 
end

pts = zeros(size(seqA));
for i = 1 : size(seqA,1)
    pts(i,:) = abs(seqA(i,:) - seqB(i,:)) <= .5 ;
end


[tmp,ix] = sort(dist,'descend');
subplot(3,3,1)
plot(seqA(:,ix(floor(length(ix)*.95))))
hold on ; plot(seqB(:,ix(floor(length(ix)*.95))),'g')
title('5th percentile')

subplot(3,3,4)
plot(seqA(:,ix(floor(length(ix)*.85))))
hold on ;plot(seqB(:,ix(floor(length(ix)*.85))),'g')
title('15 percentile')

subplot(3,3,7)
plot(seqA(:,ix(floor(length(ix)*.75))))
hold on ;
plot(seqB(:,ix(floor(length(ix)*.75))),'g')
title('25 percentile')

subplot(3,3,2)
plot(seqA(:,ix(floor(length(ix)*.50))))
hold on ;
plot(seqB(:,ix(floor(length(ix)*.50))),'g')
title('50 percentile')

subplot(3,3,5)
plot(seqA(:,ix(floor(length(ix)*.25))))
hold on ;
plot(seqB(:,ix(floor(length(ix)*.25))),'g')
title('75 percentile')

subplot(3,3,8)
plot(seqA(:,ix(floor(length(ix)*.05))))
hold on ;
plot(seqB(:,ix(floor(length(ix)*.05))),'g')
title('95 percentile')

% subplot(4,3,10)
% plot(seqA(:,ix(1)))
% hold on
% plot(seqB(:,ix(1)),'g')
% title('Best Separation')

subplot(3,3,6)
hist(sum(pts,2),20)
xlabel('Number of Bad Beads')
title('Bad bead count across samples within .5'); 

subplot(3,3,9)
hist(dist,20)
xlabel('L2 Norm Distance'); ylabel('Count')
title('L2 Norm Distance between matched pairs')
hold on;
plot([dist(ix(floor(length(ix)*.95))); dist(ix(floor(length(ix)*.95)))],[0; 60],'m')
plot([dist(ix(floor(length(ix)*.85))); dist(ix(floor(length(ix)*.85)))],[0; 60],'m')
plot([dist(ix(floor(length(ix)*.75))); dist(ix(floor(length(ix)*.75)))],[0; 60],'m')
plot([dist(ix(floor(length(ix)*.50))); dist(ix(floor(length(ix)*.50)))],[0; 60],'m')
plot([dist(ix(floor(length(ix)*.25))); dist(ix(floor(length(ix)*.25)))],[0; 60],'m')
plot([dist(ix(floor(length(ix)*.05))); dist(ix(floor(length(ix)*.05)))],[0; 60],'m')


% subplot(4,3,[3 6])
% plot(pct); 
% title('Percentage samples crossed per matched pair')
% xlabel('Bead'); ylabel('Percentage Sample Crossed')

subplot(3,3,3)
plot(pct,dist,'.')
title('Global and pointwise error for each bead')
xlabel('Proportion Sample Crossed')
ylabel('L2 Norm Distance')

pts = sum(pts,2) ; 
% orient landscape
% saveas(gcf,horzcat(fname,'_PerformanceEval.pdf'),'pdf')
end