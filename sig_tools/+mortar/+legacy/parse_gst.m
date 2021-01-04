%PARSE_GST Parse GST format file
% a 2 column tab delimited file, with the following compulsory column
% headers [SAMPLE_ID, EXP_SET]

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT
function gst = parse_gst(fname, isdu)
if ~exist('isdu','var')
   isdu=false
end

if exist(fname,'file')
    gst = parse_tbl(fname, false);
    fn = fieldnames(gst);
    
    if isempty(strmatch('SAMPLE_ID',fn, 'exact'))
        error('SAMPLE_ID field missing from file');
    end
    
    if isempty(strmatch('EXP_SET',fn, 'exact'))
        error('EXP_SET field missing from file');
    end
    
    if isdu
     if isempty(strmatch('SAMPLE_TYPE',fn, 'exact'))
        error('SAMPLE_TYPE field missing from file');
     end
    end
       
else
    error('%s not found',fname)
end
