function gct = parse_csv(dsfile, varargin)
% PARSE_CSV Parse a Luminex CSV file.
%   GCT = PARSE_CSV(FN) Parses FN and returns a structure.
%   GCT = PARSE_CSV(FN, PARAM, VALUE) specify optional parameters. Valid
%   options are:
%   'type'  : char or cell array, data type to read. Default is 'Median'. Can be a list of datatypes.
%   'class' : char, precision. Default is 'double'

pnames = {'type', 'class', 'skip_empty', 'nan_value', 'mfi_scale_factor'};
dflts =  {'median', 'double', true, 0, 1};
args = parse_args(pnames, dflts, varargin{:});

% Scale MFI data if true
apply_mfi_scaling = abs(args.mfi_scale_factor-1)>eps;

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
if ischar(args.type)
    dstype = {args.type};
elseif iscell(args.type)
    dstype = args.type;
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
    while fid>0 && ~feof(fid)
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
        gct(dtidx) = parse_csvblock(fid, nc, hdr, args);
        gct(dtidx).src = dsfile;
        gct(dtidx).dstype = dt;
        if apply_mfi_scaling && strcmpi(dt, 'median')
            dbg(1, 'Rescaling MFI values by %f', args.mfi_scale_factor);
            gct(dtidx).mat = gct(dtidx).mat .* args.mfi_scale_factor;
        end
    else
        warning('Datatype blocks not found')
        disp(setdiff(upper(dstype), {gct.dstype}))
    end    
end
fclose(fid);
fprintf ('Done.\n');

end

function gct = parse_csvblock(fid, nc, hdr, args)
gct = mergestruct(mkgctstruct, struct('hdr', [], 'dstype', ''));
gct.hdr = hdr;
r = csv_read_line(fid);
gct.rid = r(3:end-1);
nr = length(gct.rid);
fprintf ('[%dx%d]\n', nr, nc);
gct.mat = zeros(nr, nc, args.class);
gct.cid = cell(nc,1);

for ii=1:384   
    r = csv_read_line(fid);
    if isempty(r{1})
        break
    else
        v = r(3:end-1);
        nv = length(v);
        if nv>0
            assert(isequal(nv, nr),...
                'Value count mismatch for %s expected %d, found %d',...
                r{1}, nr, nv)
            % val = max(str2double(v), 0);
            % nz = nnz(val);
            % sscanf is faster
            val = zeros(nv, 1);
            ne = 0;
            for jj=1:nv
                [a, count] = sscanf(v{jj}, '%f');
                ne = ne + count;
                if count
                    val(jj) = a;
                end
            end
            if ne>0 || ~args.skip_empty
                gct.cid{ii} = r{1};
                gct.mat(:, ii) = val;
            end
        else
            warning('Blank row at %s, skipping', r{1});
        end
    end
end
keep = ~cellfun(@isempty, gct.cid);
if ~isequal(nnz(keep), nc)
    warning('Sample count mismatch, expected %d found %d', nc, nnz(keep))
    disp('Empty Column Indices:');
    disp(find(~keep));
end
gct.cid = gct.cid(keep);
gct.mat = gct.mat(:, keep);
gct.rdict = list2dict(gct.rhd);
gct.cdict = list2dict(gct.chd);
gct = ds_nan_to_val(gct, args.nan_value);

end

function line = csv_read_line(fid)
line{1} = '';
if ~feof(fid)
    raw = fgetl(fid);
    if ~isempty(raw)
        line = textscan(raw, '%q', 'delimiter', ',');
        line = line{1};
    end
end
end
