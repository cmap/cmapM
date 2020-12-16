function rv = doxygen(param1, param2, auto_param)
% function rv = doxygen(param1, param2) is ignored
% Here comes a short description text
%
% After the first empty documentation line, paragraphs of the detailed
% description begin.
%
% Here, you have the following formatting possibilites:
% Adding LaTeX code in the text with \verbatim @f$ \sum_{n=0}^N \frac{1}{n} @f$ \endverbatim
% @f$ \sum_{n=0}^N \frac{1}{n} @f$ or as an
% equation block with @verbatim @f[ \sum_{n=0}^N \frac{1}{n}. @f] @endverbatim.
% @f[ \sum_{n=0}^N \frac{1}{n}. @f] Doxygen commands
% always begin with an at-character(\@) OR a backslash(\\).
%
% Words prepended by \\c are written in a \c type-writer font.
% Words prepended by \\b are written in a \b bold font.
% Words prepended by \\em are written in an \em emphasized font.
%
% Blocks starting with @@verbatim or @@code and are ended with @@endverbatim or
% @@endcode are written unformatted in a type-writer font and are not
% interpreted by doxygen.
%
% Example:
% @verbatim
%                /| |\
%               ( |-| )
%                ) " (
%               (>(Y)<)
%                )   (
%               /     \
%              ( (m|m) )  hjw
%            ,-.),___.(,-.\`97
%            \`---\'   \`---\'
% @endverbatim
%
% Paragaphs starting with line ending with a double-colon:
% are started with a bold title line
%
% If, however, a double-colon at the end of a line is succeeded by: 
% whitespace characters, like spaces or tabulators the line is not written in a
% bold font.
%
% @note As regularly commands like @verbatim \c @f$, @f$ @f[, @f] @endverbatim
% look too distracting in matlab documentation output, the following shortcust
% exist: The doxygen filter translates
%  - @verbatim 'word' to \c word @endverbatim resulting in the output: 'word',
%  - @verbatim `x` to @f$x@f$ @endverbatim resulting in the output: `x` and 
%  - @verbatim ``x`` to @f[x.@f] @endverbatim resulting in the output: ``x``.
%
% You therefore need to be careful with the use of characters @verbatim ' `
% @endverbatim. If you want to say something about the transposed of a Matrix
% 'A', better do it in a Tex-Environment as `A' * B'` or in a verbatim/code
% environment as
% @code A' * B' @endcode
%
% Listings can be added by prepending lines with a dash(-)
%  - list 1 item which can also include
%   newlines
%  - list 2 item
%    - and they can be nested
%    - subitem 2
%    .
%  - list 3 item
%
% and they are ended by an empty documentation line.
%
% Enumerations can be added by prepending lines with a dash and hash (-#)
%  -# first item
%  -# second item
%  -# third item
%
% Lines beginning with the words "Parameters" or "Return values" start a block
% of argument respectively return argument descriptions.
%
% Parameters:
%  param1: first parameter
%
% Return values:
%  rv: return value
%
% A line beginning with the words "Required fields of", "optional fields of" or
% "generated fields of" start a block for descriptions for fields used by the
% parameters or generated for the return values.
%
% Required fields of param1:
%  test: Description for required field param1.test
%
% Optional fields of param2:
%  test2: Description for optional field param2.test2
%
% Generated fields of rv:
%  RB: Description for generated field rv.RB
%
%

% After the first non-comment line the function body begins:

%| Comment blocks starting with %| are interpreted as Doxygen documentation
% blocks and can include doxygen commands like

%| \todo There needs to be done something in this file

% fields of parameters that are used in the function body are added to the
% required fileds list automatically, if they are not documentated yet.
param1.auto_added;

param2.auto_added;

% fields of return values that are assigned somewhere in the function body are
% also added automatically to the list of generated fields
rv.auto_added  = 1;
rv.sub.auto_added = 2;

param1.sub.auto_added;

auto_param.auto_field;

function c=second_function_without_docu(a,b)

function [d,e,f]=third_function_with_sev_retvals(auto_param)
% a third (private) function in the test file with serveral return values
%
% Return values:
% d : a return value

function [d,e,f]=third_function_without_parameters
% function [d,e,f]=third_function_without_parameters
% a third (private) function in the test file without parameters
%
% Return values:
% d : a return value

%| \docupdate
