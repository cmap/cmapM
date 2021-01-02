%PARSE_CLS Read .cls class label format
% [CL,CN,NL] = PARSE_CLS(FNAME)
% Reads .cls file FNAME and returns the class labels CL, user-visible name for each class CN
% and a list numeric class labels [class1 = 1, class2=2,...]
% 
% Format Details:
% The first line of a CLS file contains numbers indicating the number of
% samples and number of classes. The number of samples should correspond to
% the number of samples in the associated RES or GCT data file.
% 
% Line format:      (number of samples) (space) (number of classes) (space) 1
% 
% Example:          58 2 1
% 
% The second line in a CLS file contains a user-visible name for each
% class. These are the class names that appear in analysis reports. The
% line should begin with a pound sign (#) followed by a space.
% 
% Line format:      # (space) (class 0 name) (space) (class 1 name)
% 
% Example:    # cured fatal/ref
% The third line contains a class label for each sample. The class label
% can be the class name, a number, or a text string. The first label used
% is assigned to the first class named on the second line; the second
% unique label is assigned to the second class named; and so on. (Note: The
% order of the labels determines the association of class names and class
% labels, even if the class labels are the same as the class names.) The
% number of class labels specified on this line should be the same as the
% number of samples specified in the first line. The number of unique class
% labels specified on this line should be the same as the number of classes
% specified in the first line.
% Line format:      (sample 1 class) (space) (sample 2 class) (space) ... (sample N class)
% Example:    0 0 0 ... 1 1

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

function [cl,cn,nl,cedges] = parse_cls(fname)

try 
     full=textread(fname,'%s','delimiter','\n');
catch
	fprintf ('Error opening %s\n',fname);
end

%read headerlines
%first line
l1 = full{1};

%find number of rows and cols
x=strread(l1,'%s');

%number of samples
ns=str2num(x{1});

%number of classes
nc=str2num(x{2});

%second line (class names)
l2 = full{2};

% if line starts with a '#' then the remaining are the names
ishash=strfind(l2,'#');
if (ishash)
    x=strread(strrep(l2,'#',''),'%s');
	cn = {x{1:end}};
    %next line has the sample labels
    l3=full{3};
else
    % line may be missing so we introduce dummy names.
    for ii=1:nc
        cn{ii} = sprintf('class%d',ii);
    end
    %sample labels are in the current line
    l3=l2;
end

if ~isequal(length(cn),nc) error('Incorrect number of class labels'); end

%third line
%phenotype labels

cl=strread(l3,'%s');

%number of unique class labels should equal number of classes
[ucl,i,j] = unique(cl);
if ~isequal(length(ucl),nc) error ('Invalid class labels'); end

% 'unique' sorts the data so...
% find the order of labels in original list
ol = {cl{sort(i)}};

%create array with numeric phenotype labels
% class1=1, class2=2 ...
nl=zeros(ns,1);
cedges=zeros(nc,2);
for ii=1:nc;
 ind=strmatch(ol{ii},cl,'exact');
 nl(ind)=ii;
 cedges(ii,1)=min(ind,[],1);
 cedges(ii,2)=max(ind,[],1);
end

%the sample labels should match the number of samples
if ~isequal(length(cl),ns) error('Incorrect number of samples'); end


