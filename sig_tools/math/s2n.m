function sn = s2n(ge,nl,nclass,loo)
%S2N Compute signal to noise in gene expression for N classes.
%
%   SN = S2N(GE,NL,NCLASS) Computes the signal to noise metric from the 
%   gene expression matrix GE,given numeric phenotype class labels NL for 
%   NCLASS number of classes. 
%   Inputs:
%   GE : matrix with dimensions: nfeature x nsample 
%   NL : numeric array of length samples with class1=1 and class2=2. 
%   NCLASS : scalar, number of classes
%
%   Outputs:
%   SN : array of length=features
%
%   SN = S2N(GE,NL,NCLASS,LOO)  if LOO=1 then does leave one out
%   re-sampling of GE to compute S2N scores. SN then is a structure:
%   SN(1..NCLASS):
%        .score (nfeature x nsample)
%        .nk (NCLASS x 1)
%        .dropped (nsample x 1)

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

doloo = 0;

%do leave one out?
if (exist('loo','var'))
    if isequal(loo,1)
        doloo=1;
    end
end

% Two Classes
% c1 = nl==1;
% %class 1 indices
% c1ind=find(c1);
% %class 2 indices
% c2ind =find(~c1);
% 
% %class 1 mean and std of expresssion
% c1ge = ge(:,c1ind);
% c1mu = mean (c1ge,2);
% c1sigma = std(c1ge,0,2);
% 
% %class 2 mean and std of expresssion
% c2ge = ge(:,c2ind);
% c2mu = mean (c2ge,2);
% c2sigma = std(c2ge,0,2);
% 
% %signal to noise ratio
% sn = (c1mu - c2mu)./(c1sigma + c2sigma);


if (~doloo)
    % n classes
    nr = size(ge,1);

    sn=zeros(nr,nclass);

    % mu = zeros(nr,nclass);
    % sigma = zeros(nr,nclass);

    %for each class compute the s2n score
    for ii=1:nclass

        c1 = nl==ii;
        c0 = ~c1;

        c1ge = ge(:,c1);
        c1mu = mean(c1ge,2);
        c1sigma = std(c1ge,0,2);
        %fix low std
        c1sigma = std_fixlow(c1sigma, c1mu);

        c0ge = ge(:,c0);
        c0mu = mean(c0ge,2);
        c0sigma = std(c0ge,0,2);
        %fix low std
        c0sigma = std_fixlow(c0sigma, c0mu);

        sn(:,ii) = (c1mu - c0mu)./(c1sigma + c0sigma);
    end

    
else
    % leave k out

    %hard coded to leave one out for now
    k=1;

    truncate = inline('x(1:n)','x','n');

    [nr,nc] = size(ge);

    %initialize sn struct 
    sn=struct('score',zeros(nr,nc),'dropped',zeros(nc,1),'nk',zeros(nclass,1));
    
    %start index for each class
    last=1;
    
    %for each class compute the s2n score
    for ii=1:nclass

        c1 = nl==ii;
        c0 = ~c1;

        %noise partition remains same for each subsample
        c0ge = ge(:,c0);
        c0mu = mean(c0ge,2);
        c0sigma = std(c0ge,0,2);
        %fix low std
        c0sigma = std_fixlow(c0sigma, c0mu);

        
        %number of subsamples for leave 1 out
        nk=length(find(c1));

        classInd = find(c1);
        sn.nk(ii)=nk;
        
        for jj=1:nk

            sn.dropped(jj+last-1) = classInd(jj);
            c1subsamp = truncate(circshift(classInd,-jj),nk-k);

            c1ge = ge(:,c1subsamp);
            c1mu = mean(c1ge,2);
            c1sigma = std(c1ge,0,2);

            %fix low std
            c1sigma = std_fixlow(c1sigma, c1mu);

            sn.score(:,jj+last-1) = (c1mu - c0mu)./(c1sigma + c0sigma);
            
        end
        
        last=last+nk;
    end

end
