function outstr= substr(str, offset, len)
%{
Syntax:

outstr= substr(str, offset, len)

substr extracts a substring of length len from the string str, starting
at the specified offset. In this version, the first character position has
offset 1. (In Acklam's original code, the first character position has
offset 0, but this is inconsistent with Matlab conventions). If offset is
negative, the position is reckoned by counting backwards from the end of
the string. If len is omitted, substr returns everything to the end of the
string. If len is negative, substr removes -len characters from the end of
the string.

Examples:

   Get first character:              substr(string,  1, 1)
   Get last character:               substr(string, -1, 1)
   Remove first character:           substr(string,  2)
   Remove last character:            substr(string,  1, -1)
   Remove first and last character:  substr(string,  2, -1)

substr is a MATLAB version of Perl's substr operator.  Unlike Perl's
substr, the first character is at position 1, and no warning is
produced if the substring is totally outside the string.

Author:      Peter J. Acklam
E-mail:      pjacklam@online.no
URL:         http://home.online.no/~pjacklam

Modified by: Phillip M. Feldman, 16-May-2007
%}

% Check number of input arguments.
error(nargchk(2, 3, nargin));

n= length(str);

% Calculate starting index of substring:

if offset < 0
   lb= offset + n + 1;   % offset from end of string
   lb= max(lb, 1);
elseif offset == 0
   lb= 1;
else
   lb= offset;
end

% Calculate ending index of substring:

if nargin == 2           % substr(str, offset)
   ub= n;

else                     % substr(str, offset, len)
   if len >= 0
      ub = lb + len - 1;
   else
      ub = n + len;
   end
   ub= min(ub, n);
end

% Extract substring:

outstr= str(lb : ub);

end
