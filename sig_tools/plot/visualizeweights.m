function b = visualizeweights(weights,varargin)
% VISUALIZEWEIGHTS   Interprets weights matrix with respect to variation
%   VISUALIZEWEIGHTS(weights,varargin) will display an image of the
%   variation in weights across the rows, default, or columns. The
%   dimension of interest is disjointly blocked, without padding, and
%   variation is measured over many permutations of the dimension, defult
%   is 40 iterations. The final outcome is the median variation across 
%   these simulations. 
% 
%   Inputs: 
%       weights : a matrix of data, usually taken to be dependency weights
%       'show' : a logical indicator, true => plot result.
%       'use_sort': logical indicator, true => sort output with resepect to
%       overall variance of feature space distributions.
%       'wise': dimension of interest, either 'dependent' (rows) or 
%       'predictor' (columns). 
%       'num_labs' : The number of random permutations to smooth the output
% 
%   Outputs:    
%       b : a smoothed interpretation of the input 'weights' matrix
%       An imagesc(b) is outputted if 'show' = 1. Additionally, a plot of
%       the variance profile over the feature space is outputted if
%       'use_sort' = 1. 
% 
%   Example:                                            
%       b = visualizeweights(randn(6000,1000),'use_sort',0,'num_labs',1); 
%       visualizeweights(randn(6000,1000)*sort(rand(1000,500)),'num_labs',1); 
% 
% Author: Brian Geier, Broad 2010


pnames = {'show','use_sort','wise','num_labs'};
dflts = {1,1,'dependent',40}; 
arg = parse_args(pnames,dflts,varargin{:}); 

isParallel = spopen ; 
if ~isParallel
    arg.num_labs = 4; 
end

fun = @(block_struct) var(nonzeros(block_struct.data(:)));


switch arg.wise
    case 'dependent'
        
        b = zeros(ceil(size(weights,1)/(floor(size(weights,1)/50))),...
            size(weights,2),arg.num_labs); 
        perm = rand(size(weights,1),arg.num_labs); 
        parfor i = 1 : arg.num_labs
            [~,list] = sort(perm(:,i),'descend'); 
            b(:,:,i) = blockproc(double(weights(list,:)),...
                [floor(size(weights,1)/50),1],fun,...
                'PadPartialBlocks',0);
        end
        b = median(b,3); 
        
        if arg.use_sort
            [y,ix_s] = sort(std(weights),'descend'); 
            b = b(:,ix_s);  
            if arg.show
                figure, plot(y), xlabel('Sorted Features')
                ylabel('Variance of Distribution');
            end
        end
        if arg.show
            figure
            imagesc(b), colorbar, title('Dependent Weight View')
        end
    case 'predictor'
        b = zeros(size(weights,1),ceil(size(weights,2)/(floor(size(weights,1)/50))),...
            arg.num_labs); 
        perm = rand(size(weights,2),arg.num_labs); 
        parfor i = 1 : arg.num_labs
            [~,list] = sort(perm(:,i),'descend'); 
            b(:,:,i) = blockproc(double(weights(:,list)),...
                [1,floor(size(weights,1)/50)],fun,...
                'PadPartialBlocks',0);
        end
        b = median(b,3); 
        if arg.use_sort
            [y,ix_s] = sort(std(weights,0,2),'descend'); 
            b = b(ix_s,:);
            if arg.show
                figure, plot(y), xlabel('Sorted Features')
                ylabel('Variance of Distribution');
            end
        end
        if arg.show
            figure
            imagesc(b); colorbar, title('Predictor Weight View')
        end
end

end