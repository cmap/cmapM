function gct = parse_csv(dsfile, varargin)
% PARSE_CSV Parse a Luminex CSV file.
%   GCT = PARSE_CSV(FN) Parses FN and returns a structure.
%   GCT = PARSE_CSV(FN, PARAM, VALUE) specify optional parameters. Valid
%   options are:
%   'type'  : char or cell array, data type to read. Default is 'Median'. Can be a list of datatypes.
%   'class' : char, precision. Default is 'double'

pnames = {'type', 'class'};
dflts =  {'median', 'double'};
arg = parse_args(pnames, dflts, varargin{:});

hdrfields = {'Program';...
'Build';...
'Date';...
'SN';...
'Batch';...
'Version';...
'Operator';...
'ComputerName';...
'Country Code';...
'ProtocolName';...
'ProtocolVersion';...
'ProtocolDescription';...
'ProtocolDevelopingCompany';...
'SampleVolume';...
'DDGate';...
'SampleTimeout';...
'BatchStartTime';...
'BatchStopTime';...
'BatchDescription';...
'ProtocolPlate';...
'ProtocolMicrosphere';...
'ProtocolAnalysis';...
'NormBead';...
'ProtocolHeater'};

hdrmap = list2dict(hdrfields);
if ischar(arg.type)
    dstype = {arg.type};
elseif iscell(arg.type)
    dstype = arg.type;
else
    error('Type should be cell or char');
end

nds = length(dstype);
gct = mergestruct(mkgctstruct, struct('hdr', [], 'dstype', ''));

try    
    fid = fopen(dsfile, 'rt');
catch ME
    disp(ME.identifier)
    error('Reading %s', dsfile)
end

nc = 0;
hdr = [];
for ii=1:nds
    isdtfound = false;
    while ~feof(fid)
        x = csv_read_line(fid);
        issample = any(strcmp('Samples',x));
        isdatatype = any(strcmp('DataType:',x));
        ishdr = hdrmap.isKey(x{1});
        if issample
            nc = str2double(x(2));
        elseif isdatatype
            [dt, dtidx] = intersect_ord(upper(dstype), upper(x));
            if ~isempty(dt)
                dt = dt{1};
                isdtfound = true;                
                break
            end
        elseif ishdr            
            fn=validvar(x{1},'_');
            hdr.(fn{1}) = strtrim(print_dlm_line(x(2:end), 'dlm',' '));
        end
        
    end
    if isdtfound
        fprintf ('Reading %s from: %s ', dt, dsfile);
        gct(dtidx) = parse_csvblock(fid, nc, hdr, arg);
        gct(dtidx).src = dsfile;
        gct(dtidx).dstype = dt;
    else
        warning('Datatype blocks not found')
        disp(setdiff(upper(dstype), {gct.dstype}))
    end    
end
fclose(fid);
fprintf ('Done.\n');

end

function gct = parse_csvblock(fid, nc, hdr, arg)
gct = mergestruct(mkgctstruct, struct('hdr', [], 'dstype', ''));
gct.hdr = hdr;
r = csv_read_line(fid);
gct.rid = r(3:end-1);
nr = length(gct.rid);
fprintf ('[%dx%d]\n', nr, nc);
gct.mat = zeros(nr, nc, arg.class);
gct.cid = cell(nc,1);
for ii=1:nc
    r = csv_read_line(fid);
    if isempty(r)
        break
    else
        gct.cid{ii} = r{1};
        % set nan's to zero
        gct.mat(:, ii) = max(str2double(r(3:end-1)), 0);
    end
end
gct.rdict = list2dict(gct.rhd);
gct.cdict = list2dict(gct.chd);
end

function line = csv_read_line(fid)
raw = fgetl(fid);
if ~isempty(raw)
    line = textscan(raw, '%q', 'delimiter', ',');
    line = line{1};
else
    line{1} = '';
end
end
