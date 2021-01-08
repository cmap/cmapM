function R = train_model(dependent,landmarks,model_type,ncomps)
% TRAIN_MODEL   Build a dependency matrix R
%   R = train_model(dependent,landmarks,model_type,ncomps) will build a
%   dependency matrix R given a set of dependent and landmark genes. The
%   model type defines the mapping between the dependent and landmark
%   genes. 
%   Inputs: 
%       dependent: A q by n matrix of dependent genes
%       landmarks: A p by n matrix of landmark genes (predictors)
%       model_type: A string specifying the model type, default is least
%       squares, 'ls', but can be any of the following
%           'lspinv' - least squares with offset using psuedoinverse
%           'ls' - least squares with offset using inverse
%           'ls-zscore' - least squares with model offset and z-scored
%           inputs, uses inverse
%           'lsnullpinv' - least squares without model offset, using
%           psuedoinverse
%           'lsnull' - least squares with model offset, using inverse
%           'linreg' - standard matrix solution with model offset using
%           psuedoinverse
%           'linregNULL' - standard matrix solution without model offset
%           using psuedoinverse
%           'pls' - partial least squares solution
%           'pls-zscore' - partial least squares solution
%           'grnn' - generalized regression neural network, requires a lot
%           of memory depending on number of predictors and responses. The
%           output is a network. 
%       ncomps: The number of principal components used by partial least
%       squares. only needed for 'pls' or 'pls-zscore', default is 50
%   Output: 
%       R - a q by p dependency matrix
% 
% see also plsregress, newgrnn, pinv
% 
% Author: Brian Geier, Broad 2010

if nargin ==3 
    ncomps = 50;
end
switch model_type
    case 'lspinv'
        landmarks = [ones(1,size(landmarks,2)) ; landmarks]; 
        R = (pinv(landmarks*landmarks')*landmarks*dependent')';
    case 'ls'
        landmarks = [ones(1,size(landmarks,2)) ; landmarks]; 
        R = (inv(landmarks*landmarks')*landmarks*dependent')'; 
    case 'ls-zscore'
        landmarks = zscore(landmarks')'; 
        landmarks = [ones(1,size(landmarks,2)) ; landmarks]; 
        R = (inv(landmarks*landmarks')*landmarks*dependent')';
    case 'lsnullpinv'
        R = (pinv(landmarks*landmarks')*landmarks*dependent')'; 
    case 'lsnull'
        R = (inv(landmarks*landmarks')*landmarks*dependent')'; 
    case 'linreg'
        R = dependent*pinv([ones(1,size(landmarks,2)); landmarks]); 
    case 'linregNULL'
        R = dependent*pinv(landmarks); 
    case 'pls'
        [~,~,~,~,R] = plsregress(landmarks',dependent',min(ncomps,size(landmarks,1)));  
        R = R'; 
    case 'pls-zscore'
        [~,~,~,~,R] = plsregress(zscore(landmarks'),dependent',...
            min(ncomps,size(landmarks,1)));  
        R = R';         
    case 'grnn'
        R = newgrnn(landmarks,dependent,4.5) ; 
    case 'new-model'
        % put new model here
        
    otherwise
        error('unsupported model type')
end

end