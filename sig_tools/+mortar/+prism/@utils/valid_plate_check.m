% valid_plate_check screens for problematic plate CSVs: missing median/bead
% count fields, missing rows/columns, incorrect bead sets
% plist = valid_plate_check(plates, plate_path, varargin)
% Returns cell array of valid plates, report file
% Arguments:
%   plates - cell array of plate names
%   plate_path - 'where/plates/live', path to directory containing plates
%   'type' - string (either 'Median' or 'Count'), data type to read from
%   CSV, default 'Median'
%   'rpt' - string, name of report file, default 'report.txt' (saves in same folder as plate CSVs)
%   'bsetcheck' - logical, whether or not to check beadsets, default false
%   'bsets' - cell array/text file of beadsets in format 'XXXX', default {''}
%   'checkdim' - logical, whether or not to check dimensions, default false

function plist = valid_plate_check(plates, plate_path, varargin)

pnames = {'type','rpt','bsetcheck','bsets','checkdim'};
dflts = {'Median','report.txt',false,{''},false};
args = parse_args(pnames, dflts, varargin{:});


% check plate_path
if ~isdir(plate_path)
    error('Incorrect plate path');
end

if ~ismember(args.type,{'Median','Count'})
    error('Data type must be ''Median'' or ''Count''');
end


fid = fopen(fullfile(plate_path,args.rpt),'w');
fprintf(fid,'Error: plate');

%logical array - tells whether a plate passes
ind = false(length(plates),1);

tic;
for p=1:length(plates)
    fname = fullfile(plate_path,plates{p});
    
    %does file exist?
    if ~isfileexist(fname,'file')
       msg=sprintf('%s does not exist',fname);
       disp(msg);
       fprintf(msg);
       continue; 
    end
    
    [~,ds] = evalc('parse_csv(fname,''type'',args.type);');
    
    %check if data type is available
    if isempty(ds.mat)
		msg = sprintf('%s data not available: %s',args.type, plates{p});
		disp(msg);
		fprintf(fid,msg);
    	continue;
    end
    
    %check dimensions
    if args.checkdim
        [nr,nc] = size(ds.mat);
        if nc ~= 384 || nr ~= 100
            msg = sprintf('Incorrect dim (%d x %d): %s',nr,nc,plates{p});
            disp(msg);
            fprintf(fid,msg);
            continue;
        end
    end
    
    
%% subject to change - dependent on naming scheme of data  
    %check beadset
    if args.bsetcheck
        % bead set in plate name - format 'B.XXXX'
        [f,l] = regexp(plates{p},'B[.][A-Z]{4}');
        dsbeads = plates{p}(f+2:l);
        % dsbeads = regexprep(plates{p},{'PR[.]ROC[0-9]*_P[.][A-Z]*','_\w*_','B[.]','[0-9]*[.]csv'},'');
        % dsbeads = regexprep(ds.hdr.ProtocolName,{'_',' ','PRISM','BEAD','SETS','POOL'},'');
        if isfileexist(args.bsets)
            beadfile = fopen(args.bsets);
            bsets = textscan(beadfile,'%s');
            bsets = bsets{:};
            fclose(beadfile);
        else
            bsets = args.bsets;
        end

        if ~ismember(dsbeads,bsets)
            msg = sprintf('Incorrect beadset %s: %s',dsbeads,plates{p});
            disp(msg);
            fprintf(fid,msg);
            continue;
        end
    end
    
    %plate passes
    ind(p)=true;  
end

fclose(fid);
plist=plates(ind);
disp('[Done.]')
toc;