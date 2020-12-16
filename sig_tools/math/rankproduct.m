function rank_product = rankproduct(ranks,cl)
% RANKPRODUCT Computes the rank product for each feature and class
%   [rank_product,ranks] = rankproduct(ranks,cl) will compute the rank
%   product of each feature and class, given replicates
%   Inputs: 
%       ranks : a p by N matrix, includes replicates per class
%       cl : a cell array specifying the class of each column
%   Output: 
%       rank_product : a p by n matrix, where n = # classes
% 
% Author: Brian Geier, Broad 2010

if size(ranks,2) ~= length(cl)
    error('there must be a category label for each rank column'); 
end

groups = unique_ord(cl); 

rank_product = zeros(size(ranks,1),length(groups));

for i = 1 : length(groups)
    rank_product(:,i) = prod(ranks(:,strcmp(groups{i},cl)),2)...
        .^(1/sum(strcmp(groups{i},cl))); 
end