function writepng(figurenumber,filename)
%WRITEPNG Write a figure to a Portable Network Graphics (PNG) file 
%
%   WRITEPNG(FIGURENUMBER,FILENAME) writes the figure identified
%   by FIGURENUMBER as a graphic to a file named FILENAME in PNG format.
%
%   Input:
%   FIGURENUMBER : number of figure
%   FILENAME     : name for graphics file

figure(figurenumber); pause(2)
if is_octave()
  % ToDo: Find a way to implement as for Matlab
  saveas(gcf,filename,'png');
else
  [X,MAP]=frame2im(getframe(gcf));
  imwrite(X,filename,'png');
end

if nargin==3
 eval(['!/usr/bin/convert ',filename,'.png ',filename,'.gif '])
end

end
