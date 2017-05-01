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

pnames = {'parallel', 'out', 'debug', ...
    'setrnd', 'rndseed', ...
    'include_well', 'exclude_well'};
dflts = { true, '.', false,...
    true, '', ...
    '', ''};
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

d = dir(fullfile(dspath, '*.lxb'));
fn = {d.name}';
nall = length(fn);
wn = get_wellinfo(fn);

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
current_pool = [];
if arg.parallel
    try
        current_pool = gcp;
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

%% check LXBs
[isok, bad] = check_lxb(dspath);
if ~isok
    disp(bad);
    error('Bad LXB files found, fix before running dpeak')    
end

%
pkstats(1:NANALYTE, 1:nsample) =  struct('pkexp',[], 'pksupport',[], ...
    'pksupport_pct',[], 'pkheight',[], 'totbead',[], ...
    'ngoodbead',[], 'medexp',[], 'method',[]);

% pkstats = zeros(nsample, nanalyte);
% ntag = 2;
% dpmat = zeros(nanalyte, nsample, ntag);
% supmat = zeros(nanalyte, nsample, ntag);
% suppctmat = zeros(nanalyte, nsample, ntag);
isdebug = arg.debug;
% isdebug = true;
parfor ii=1:nsample
    % Each well reinitialized to same state
    RandStream.setGlobalStream(RandStream('mt19937ar'));
    defaultStream = RandStream.getGlobalStream();
    defaultStream.State = savedState;
    
    fprintf ('%d/%d %s\n',ii,nsample, fn{ii});
    lxb = parse_lxb(fullfile(dspath, fn{ii}));
    printdbg(sprintf ('%d/%d %s\tDone Parsing\n',ii,nsample, fn{ii}), isdebug);
    p=[];

    try
        p = detect_lxb_peaks_multi(lxb.RP1, lxb.RID, varargin{:});
        dbg(isdebug, '%d/%d %s\tDone detection\n',ii,nsample, fn{ii});
        pkstats(:, ii) = p;
    catch exception
        disp(exception)
        fprintf('%s\t%d [%dx%d]\n', fn{ii}, length(p), size(p,1), size(p,2));        
        error('%d/%d %s error',ii,nsample, fn{ii})
    end
    dbg(isdebug, '%d/%d %s\tDone Assignment\n',ii,nsample, fn{ii});
%     assign = assign_lxb_peaks(pkstats, 'ntag', ntag);
       
end

if arg.parallel
    delete(current_pool);
end

for ii=1:nsample
    %save source name
    [pkstats(:, ii).src] = deal(fn{ii});
    % save analyte ids
    [pkstats(:,ii).analyte] = glabels{:};
end