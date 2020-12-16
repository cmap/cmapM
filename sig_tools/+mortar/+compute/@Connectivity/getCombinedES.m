function comb_score = getCombinedES(upes, dnes, rescale)
% GETCOMBINEDES Compute Combined Enrichment score
%   CS = GETCOMBINEDES(UPES, DNES) returns a combined enrichment
%   scores, given a list of up and down enrichment scores. UPES, DNES and
%   CS are vectors of the same dimensions. By default the scores are
%   rescaled to range from +1 to -1. 
%
%   CS = GETCOMBINEDES(UPES, DNES, false) Does not rescale the scores.

if ~isvarexist('rescale')
    rescale = true;
end

%convert to column vectors
upes=upes(:);
dnes=dnes(:);

assert(isequal(numel(upes), numel(dnes)),...
    'Dimension mismatch between up and down scores');

upsign = sign(upes);

% Combined score with sign based on up score
% comb_score = 0.5*(abs(upes) + abs(dnes)).*upsign;
comb_score = 0.5*(upes - dnes);

% Nullize scores where up and down scores have the same sign
nulls = upsign == sign(dnes);
comb_score(nulls) = 0;

% Normalize scores to range [+1,-1]
% exclude zeros
% posind = comb_score>0;
% negind = comb_score<0;

if rescale
    %include_zeros_justin_style
    posind = comb_score>=0;
    negind = comb_score<=0;
    % Negative scores range from -1 to 0
    if any(negind)
        neg_min = min(comb_score(negind));
        neg_max = max(comb_score(negind));
        neg_denom = neg_max - neg_min;
        
        if neg_denom == 0
            %only one entry
            comb_score(negind) = -1;
        else
            comb_score(negind) = (comb_score(negind) - neg_max) ./neg_denom;
        end
    end
    
    % Positive scores range from 0 to +1
    if any(posind)
        pos_min = min(comb_score(posind));
        pos_max = max(comb_score(posind));
        pos_denom = pos_max - pos_min;
        
        if pos_denom == 0
            %only one entry
            comb_score(posind) = 1;
        else
            comb_score(posind) = (comb_score(posind) - pos_min) ./pos_denom;
        end
    end
end
