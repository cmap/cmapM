function out=rgba(color,alpha)
%RGBA Translates a color from multiple formats into a [R G B alpha] color-transparency
%
%   [RGBa] = RGBA(COLOR,ALPHA)
%   Matlab color-transparency is returned as [R G B alpha] where alpha 
%   specifies the transparency.
%
%   INPUTS:
%   color : number of optional arguments
%   alpha : blending of symbol face color (0.0 transparent through 1.0 opaque)
%
%   OUTPUTS:
%   RGBa : color + transparency returned as 4-element vector [R G B alpha],
%          where [R G B] is a standard Matlab color triplet and 
%          0 <= alpha <= 1 is the amount of blending
%
%   DESCRIPTION:
%   The rgb triplet function is used to obtain the Matlab color triplet and 
%   the transparency added to the vector. Refer to the documentation on the 
%   RGB function for allowed COLOR values.
%
%   DEPENDENCY:
%   RGB triplet function of Ben Mitch:
%   https://www.mathworks.com/matlabcentral/fileexchange/1805-rgb-m
%
%   EXAMPLE:
%   type "rgba(demo,1.0)" to get started with opaque
%   type "rgba(demo,0.5)" to get started with semi-transparent

%   This is a simple interface built onto the RGB function written by 
%   Ben Mitch with modification of his demo program.
%
% Author: Peter A. Rochford
%         Symplectic, LLC
%         www.thesymplectic.com
%         prochford@thesymplectic.com

% Check for demo
if strcmp(color,'demo')
   rgb_demo(alpha);
   return;
end

RGB3 = rgb(color);
out = [RGB3(1); RGB3(2); RGB3(3); alpha];

end % function rgba

 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEMO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function rgb_demo(alpha)
%alpha %debug
 
figure(1)
clf
cols = get_cols;
cols = {cols{:,1}}';
cols = { cols{:}, ...
    'k', ...
    'r', ...
    'g', ...
    'b', ...
    'y', ...
    'm', ...
    'c', ...
    'w', ...
    '', ...
    'extremely dark green', ...
    'very dark green', ...
    'dark green', ...
    'slightly dark green', ...
    'green', ...
    'slightly pale green', ...
    'pale green', ...
    'very pale green', ...
    'extremely pale green', ...
};
 
height=9;
x=0;
y=0;
for n=1:length(cols)
    rect(x,y,cols{n},alpha)
    y=y+1;
    if y==height
        x=x+2;
        y=0;
    end
end
if y==0 x=x-2; end
axis([0 (x+2) 0 height])
title(['names on different rows are alternates (alpha=' num2str(alpha) ')'])
end % function rgb_demo
 
function rect(x,y,col,alpha)
if isempty(col) return; end

% Get color triplet
col_=col;
if iscell(col) col=col{1}; end
colrgb=rgb(col);

% Draw rectangle with color-transparency
r = patch([x+0.1 x+1.9 x+1.9 x+0.1],[y+0.1 y+0.1 y+0.9 y+0.9], colrgb);
r.FaceAlpha = alpha; % set transparency

if strcmp(col(1),'u') & length(col)==2
    t=text(x+1,y+0.5,{'unnamed',['colour (' col(2) ')']});
else
    t=text(x+1,y+0.5,col_);
    if sum(colrgb)<1.5 set(t,'color',[1 1 1]); end
end
set(t,'horizontalalignment','center')
set(t,'fontsize',10)
end % function rect
 
function rgb_list
cols=get_cols;
disp(' ')
for n=1:size(cols,1)
    code=cols{n,2};
    str=cols{n,1};
    str_=[];
    for m=1:length(str)
        str_=[str_ str{m} ', '];
    end
    str_=str_(1:end-2);
    if strcmp(str_(1),'u') & length(str_)==2
        str_=['* (' str_(2) ')'];
    end
    disp(['  [' sprintf('%.1f  %.1f  %.1f',code) '] - ' str_])
end
disp([10 '* colours marked thus are not named - if you know their' 10 '  designation, or if you feel sure a colour is mis-named,' 10 '  email me (address via help) or comment at' 10 '  www.mathworks.com/matlabcentral - "rgb demo" to see them' 10])
 
end % function rgb_list
 
function cols=get_cols
 
cols={
    'black', [0 0 0]; ...
    'navy', [0 0 0.5]; ...
    'blue', [0 0 1]; ...
    'u1', [0 0.5 0]; ...
    {'teal','turquoise'}, [0 0.5 0.5]; ...
    'slateblue', [0 0.5 1]; ...
    {'green','lime'}, [0 1 0]; ...
    'springgreen', [0 1 0.5]; ...
    {'cyan','aqua'}, [0 1 1]; ...
    'maroon', [0.5 0 0]; ...
    'purple', [0.5 0 0.5]; ...
    'u2', [0.5 0 1]; ...
    'olive', [0.5 0.5 0]; ...
    {'gray','grey'}, [0.5 0.5 0.5]; ...
    'u3', [0.5 0.5 1]; ...
    {'mediumspringgreen','chartreuse'}, [0.5 1 0]; ...
    'u4', [0.5 1 0.5]; ...
    'sky', [0.5 1 1]; ...
    'red', [1 0 0]; ...
    'u5', [1 0 0.5]; ...
    {'magenta','fuchsia'}, [1 0 1]; ...
    'orange', [1 0.5 0]; ...
    'u6', [1 0.5 0.5]; ...
    'u7', [1 0.5 1]; ...
    'yellow', [1 1 0]; ...
    'u8', [1 1 0.5]; ...
    'white', [1 1 1]; ...
    };
 
for n=1:size(cols,1)
    if ~iscell(cols{n,1}) cols{n,1}={cols{n,1}}; end
end
 
end % function get_cols
 
% converts a DWORD into a four byte row vector
function out=bytes4(in)
 
out=[0 0 0 0];
if in<0 | in>(2^32-1)
    warning('DWORD out of range, zero assumed');
    return;
end
 
N=4;
while(in>0)
    out(N)=mod(in,256);
    in=(in-out(N))/256;
    N=N-1;
end
 
end % function bytes4
