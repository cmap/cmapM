% map fieldnames

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT
function newfn = mapfn(fn, mapfile, mapping, varargin)

pnames = {'unique','delimiter'};
dflts = {true, '|'};
args = parse_args(pnames, dflts, varargin{:});

nf = length(fn);
newfn = cell(nf,1);

if isstruct(mapfile)
    map = mapfile;
elseif isfileexist(mapfile)
    map = parse_record(mapfile);
else
    error('File not found: %s', mapfile);
end

tok = deal(tokenize(mapping, ':'));
[srcfield, tgtfield] = tok{:};
mapfn = fieldnames(map);
srcfield = intersect(srcfield, mapfn);
tgtfield = map_ord(mapfn, tokenize(tgtfield,',', true));


if ~isempty(srcfield) && ~isempty(tgtfield)
    
    %indices
    [cmnfn, idx] = intersect_ord({map.(srcfield{1})}, fn);
    
    if isequal(length(cmnfn), nf)
        
        ntgt = length(tgtfield);
        
        lbl=cell(nf, ntgt);
        
        for ii=1:ntgt
            lbl(:,ii) = {map(idx).(tgtfield{ii})};
        end
        
        for ii=1:nf
            newfn{ii} = print_dlm_line(lbl(ii,:),1, args.delimiter);
        end
        
        if args.unique
            [dups, dupidx, gp, repnum] = duplicates(newfn);
            if ~isempty(dups)
                newfn(dupidx) = strcat(newfn(dupidx), gen_labels(repnum,'#REP_'));
            end
        end
    else
        disp(setdiff(fn, cmnfn))
        error ('%s: could not find all mappings %s', mfilename,srcfield{1});
        
    end
end
