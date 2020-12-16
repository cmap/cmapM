function tokens = strsplit( input_string, delimiters )
%STRSPLIT  Divide a string into tokens.
%   TOKENS = STRSPLIT(STRING, DELIMITERS) divides STRING into tokens
%   using the characters in the string DELIMITERS. The result is stored
%   in a single-column cell array of strings.
%
%   Examples: 
%
%   strsplit('The quick fox jumped',' ') returns {'The'; 'quick'; 'fox'; 'jumped'}.
%
%   strsplit('Ann, Barry, Charlie',' ,') returns {'Ann'; 'Barry'; 'Charlie'}.
%
%   strsplit('George E. Forsyth,Michael A. Malcolm,Cleve B. Moler',',') returns
%   {'George E. Forsyth'; 'Michael A. Malcolm'; 'Cleve B. Moler'}


if (~isempty(input_string))
    %tokens = strread(input_string, '%s', -1, 'delimiter', delimiters);
    tokens = textscan(input_string, '%s', 'delimiter', delimiters);
    tokens = tokens{1};
else
    tokens = {};
end