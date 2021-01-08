function process_cnts(pathname,out)
% PROCESS_CNTS Routine for checking analyte counts across a collection of
% lxb files, located in pathname
%   process_cnts(pathname,out) will load each lxb file found in pathname
%   and will count the number of beads present for each of the 500
%   analytes. The output is a gct file where the sid is the location of the
%   lxb file. The output can be analyzed to see if there are plate effects
%   as well as count consistency per analytes across samples. 
%   Inputs: 
%       pathname : directory where lxb files are located. All lxb files
%       found within this directory will be loaded and processed for
%       analyte counts. 
%       out : The output directory for the gct file, which contains analyte
%       by lxb file - count information. out = fullfile(output_dir,fname)
%   Outputs: 
%       A file with count information for each analyte across samples is
%       outputted to string specifier 'out = fullfile(output_dir,fname)
% 
% Author: Brian Geier, Broad 2010

spopen ; 
files = dir(fullfile(pathname,'*.lxb')); 

cnts = zeros(500,length(files)); 
location = cell(length(files),1); 
analyte = cell(500,1); 
for i = 1 : length(files)
    location{i} = files(i).name ; 
end

for i = 1 : 500
    analyte{i} = horzcat('Analyte ',num2str(i)) ;
end

parse_lxb(fullfile(pathname,files(1).name)); % initialize gene path

parfor i = 1 : length(files)
    lxb = parse_lxb(fullfile(pathname,files(i).name));
    cnts(:,i) = getcnts(lxb.RID);
end

mkgct0(out,cnts,analyte,analyte,location);

end

function cnts = getcnts(rid)

cnts = zeros(500,1); 
for i = 1 : 500
    cnts(i) = sum(rid==i) ; 
end

end