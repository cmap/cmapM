% CLASS_MEAN_EXPRESSION Mean gene expression for N classes.
%   CME = CLASS_MEAN_EXPRESSION(GE,NL,NCLASS) Computes the mean expression 
%   from matrix GE, for each numeric phenotype class label NL for 
%   NCLASS number of classes. 
%
%   Inputs:
%   GE : matrix with dimensions: nfeature x nsample 
%   NL : numeric array of length samples with class1=1 and class2=2. 
%   NCLASS : scalar, number of classes
%
%   Outputs:
%   CME : mean expression (nfeature x nclass)
%
%   CME = CLASS_MEAN_EXPRESSION(GE,NL,NCLASS,ROBUST) If ROBUST = 1 then 
%       use median instead of mean
%
%   CME = CLASS_MEAN_EXPRESSION(GE,NL,NCLASS,ROBUST,LOO)  if LOO=1 then does leave one out
%   re-sampling of GE to compute scores. CME then is a structure:
%   CME(1..NCLASS):
%        .score (nfeature x nsample)
%        .nk (NCLASS x 1)
%        .dropped (nsample x 1)

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

% 2/22/2008, switched to single precision

function cme = class_mean_expression(ge, nl, nclass, robust,loo)

%% Two Classes
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

%% n classes
[nr,nc] = size(ge);

middle=@mean;

if exist('robust','var')

    if isequal(robust,1)
        disp('Using median');
        middle=@median;
    end
    
end

%do leave one out?
doloo = 0;
if (exist('loo','var'))
    if isequal(loo,1)
        
        doloo=1;
    end
end

if ~doloo
    cme=zeros(nr,nclass,'single');

    % mu = zeros(nr,nclass);
    % sigma = zeros(nr,nclass);

    %for each class compute the s2n score
    for ii=1:nclass

        c1 = ismember(nl,ii);

        c1ge = ge(:,c1);
        cme(:,ii) = middle(c1ge,2);

    end
else
    %hard coded to leave one out for now
    k=1;

    truncate = inline('x(1:n)','x','n');

    %initialize cme struct
    cme=struct('score',zeros(nr,nc,'single'),'dropped',zeros(nc,1),'nk',zeros(nclass,1));

    %start index for each class
    last=1;

    %for each class compute the s2n score
    for ii=1:nclass

        c1 = ismember(nl,ii);

        %number of subsamples for leave 1 out
        nk=length(find(c1));

        classInd = find(c1);
        cme.nk(ii)=nk;

        for jj=1:nk

            cme.dropped(jj+last-1) = classInd(jj);
            c1subsamp = truncate(circshift(classInd,-jj),nk-k);

            c1ge = ge(:,c1subsamp);
            cme.score(:,jj+last-1) = middle(c1ge,2);

        end

        last=last+nk;
    end
end


