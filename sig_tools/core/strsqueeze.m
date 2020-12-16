function sqs = strsqueeze(s, rep)
% STRSQUEEZE Eliminate repeating characters from a string
%   SQS = STRSQUEEZE(S, REP) Remove repeat occurrences of REP in S
%
%   Example
%       sqs = strsqueeze('foo     bar', ' ')


% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

sqs = regexprep(s, sprintf('%s+', rep), rep);
