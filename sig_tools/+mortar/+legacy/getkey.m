
% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT
function ch = getkey(h,m) 

% GETKEY - get a single keypress
%   CH = GETKEY waits for a keypress and returns the ASCII code. Accepts
%   all ascii characters, including backspace (8), space (32), enter (13),
%   etc, that can be typed on the keyboard. Non-ascii keys (ctrl, alt, ..)
%   return a NaN. CH is a double. 
%
%   CH = GETKEY('non-ascii') uses non-documented matlab 6.5 features to
%   return a string describing the key pressed. In this way keys like ctrl, alt, tab
%   etc. can also distinguished. CH is a string.
%
%   This function is kind of a workaround for getch in C. It uses a modal, but
%   non-visible window, which does show up in the taskbar.
%   C-language keywords: KBHIT, KEYPRESS, GETKEY, GETCH
%
%   Examples:
%
%    fprintf('\nPress any key: ') ;
%    ch = getkey ;
%    fprintf('%c\n',ch) ;
%
%    fprintf('\nPress the Ctrl-key: ') ;
%    if strcmp(getkey('non-ascii'),'control'),
%      fprintf('OK\n') ;
%    else
%      fprintf(' ... wrong key ...\n') ;
%    end
%
%  See also INPUT, CHAR

% for Matlab 6.5
% version 1.1 (dec 2006)
% author : Jos van der Geest
% email  : jos@jasen.nl
%
% History
% 2005 - creation
% dec 2006 - modified lay-out and help

% Determine the callback string to use
if nargin == 2,
    if strcmp(lower(m),'non-ascii'),
        callstr = ['set(gcbf,''Userdata'',get(gcbf,''Currentkey'')) ; uiresume '] ;
    else       
        error('Argument should be the string ''non-ascii''') ;
    end
else
    callstr = ['set(gcbf,''Userdata'',double(get(gcbf,''Currentcharacter''))) ; uiresume '] ;
end

% Set up the figure
% May be the position property  should be individually tweaked to avoid visibility
% fh = figureoff('keypressfcn',callstr, ...
%     'windowstyle','modal',...    
%     'position',[0 0 eps eps],...
%     'Name','GETKEY', ...
%     'userdata','timeout') ; 
if (exist('h','var'))
    fh = h;
    figparams = {'keypressfcn','windowstyle','userdata'};
    figstate=get(fh, figparams);
    set(fh, 'keypressfcn',callstr, ...
        'windowstyle','modal',...
        'userdata','timeout') ;
    delfig = false;
else    
    fh = figure('keypressfcn',callstr, ...
        'windowstyle','modal',...
        'position',[0 0 eps eps],...
        'userdata','timeout') ;
    delfig = true;
end


try    
    % Wait for something to happen
    uiwait(fh) ;
    ch = get(fh,'Userdata') ;
    if isempty(ch),
        ch = NaN ; 
    end
catch
    % Something went wrong, return and empty matrix.
    ch = [] ;
end

if delfig && ishandle(fh)
    delete(fh) ;
elseif ~delfig && ishandle(fh)
    set(fh, figparams, figstate);
end
 
