function [pkstats,fn] = detect_lxb_peaks_folder(dspath, varargin)
% DETECT_LXB_PEAKS_FOLDER Detect peaks for lxb files in a folder.
%   PKSTATS = DETECT_LXB_PEAKS_FOLDER(DSPATH) detect peaks for all LXB
%   files in DSPATH. PKSTATS is a structure array with the detected peaks
%   and support information. It is a 2-d array [numfiles x numanalytes]
%
%   PKSTATS = DETECT_LXB_PEAKS_MULTI(DSPATH 'Param1, 'Value1',...)
%   Specify optional parameters to peak detection routine. See
%   DETECT_LXB_PEAKS_SINGLE for description of the parameters.
%
% See: DETECT_LXB_PEAKS_SINGLE, DETECT_LXB_PEAKS_MULTI

dbg(1, 'dspath:  %s', dspath);

pnames = {'parallel', 'out', 'debug', ...
    'setrnd', 'rndseed', ...
    'include_well', 'exclude_well', ...
    'group_field', 'intensity_field'};
dflts = { true, '.', false,...
    true, '', ...
    '', '', ...
    'RID', 'RP1'};
arg = parse_args(pnames, dflts, varargin{:});
%save dpeak parameters
allarg = getallargs(varargin{:});

%Set/Save rng state
RandStream.setGlobalStream(RandStream('mt19937ar'));
defaultStream = RandStream.getGlobalStream();
if ~isempty(arg.rndseed)
    fprintf ('Using supplied Random number seed: %s\n', arg.rndseed)
    seed=load(arg.rndseed);
    defaultStream.State = seed.savedState;
    savedState = seed.savedState;
else
    savedState = defaultStream.State;
end
save(fullfile(arg.out, sprintf('rndseed.mat')), 'savedState')

fid = fopen(fullfile(arg.out, sprintf('%s_params.txt', mfilename)), 'wt');
print_args(mfilename, fid, allarg)
fclose(fid);

d = dir(fullfile(dspath, '*.txt'));
fn = {d.name}';
nall = length(fn);
wn = get_wellinfo(fn);

if length(wn) == 0
	dbg(1, 'detect_lxb_peaks_folder:  no well information could be parsed from the filenames, perhaps they are named incorrectly.  Do not ask me what the naming convention is though')
end

if ~isempty(arg.include_well)
    [~, keepidx] = intersect(wn, arg.include_well);
    fn = fn(keepidx);
end

if ~isempty(arg.exclude_well)
    [~, keepidx] = setdiff(wn, arg.exclude_well);
    fn = fn(keepidx);
end

nsample = length(fn);
if ~isequal(nall, nsample)
    dbg(1, 'Ignoring %d/%d files\n', nall-nsample, nall);
end

NANALYTE = 500;
glabels = num2cell(1:NANALYTE);
if arg.parallel
    try
        if matlabpool('size') == 0
            matlabpool ('open') ;
        end
    catch EM
        disp(EM)
        disp(EM.message)
        disp(EM.stack)
        fprintf('Executing Sequentially...\n');
        arg.parallel = false;
    end
else
    fprintf('Executing Sequentially...\n');
end

isdebug = arg.debug;
lxbs = cell(nsample,1);
for ii=1:nsample
    fprintf ('reading lxb:  %d/%d %s\n',ii,nsample, fn{ii});
    try
        lxbs{ii} = parse_lxb(fullfile(dspath, fn{ii}));
        printdbg(sprintf ('%d/%d %s\tDone Parsing\n',ii,nsample, fn{ii}), isdebug);
    catch exception
        fprintf(['failed to read lxb file fn{ii}:  ' fn{ii} '\n']);
    end
end
good_lxbs = ~cellfun(@isempty, lxbs);
lxbs = lxbs(good_lxbs);
fn = fn(good_lxbs);
num_good_lxbs = nnz(good_lxbs);

fprintf('%d out of %d lxbs were able to be read\n', num_good_lxbs, nsample);

%
pkstats(1:NANALYTE, 1:num_good_lxbs) =  struct('pkexp',[], 'pksupport',[], ...
    'pksupport_pct',[], 'pkheight',[], 'totbead',[], ...
    'ngoodbead',[], 'medexp',[], 'method',[]);


parfor ii=1:num_good_lxbs
    % Each well reinitialized to same state
    RandStream.setGlobalStream(RandStream('mt19937ar'));
    defaultStream = RandStream.getGlobalStream();
    defaultStream.State = savedState;
    
    lxb = lxbs{ii};
    p=[];

    try
        fprintf ('detecting peaks for lxb:  %d/%d %s\n',ii, num_good_lxbs, fn{ii});
        p = mortar.compute.L1kPipeline.detect_lxb_peaks_multi(lxb.(arg.intensity_field), lxb.(arg.group_field), varargin{:});
        dbg(isdebug, '%d/%d %s\tDone detection\n',ii,num_good_lxbs, fn{ii});
        pkstats(:, ii) = p;
    catch exception
        disp(exception)
        fprintf('%s\t%d [%dx%d]\n', fn{ii}, length(p), size(p,1), size(p,2));        
        error('%d/%d %s error',ii,num_good_lxbs, fn{ii})
    end
    dbg(isdebug, '%d/%d %s\tDone Assignment\n',ii,num_good_lxbs, fn{ii});
end

if arg.parallel
    matlabpool('close');
end

for ii=1:num_good_lxbs
    [pkstats(:, ii).src] = deal(fn{ii});
    [pkstats(:,ii).analyte] = glabels{:};
end
