function [scoreds, lfu_ds, lfd_ds] = cmap_score(varargin)

warning('DEPRECATED! Use mortar.compute.Connectivity.runCMAPQuery instead')

valid_metric = {'cs', 'wtcs'};
pnames = {'score',... 
          'rank',...
          'metric',...
          'uptag',...
          'dntag',...
          'estail'
        };
    
dflts = {'',...
         '',...
         'cs',...
         '',...
         '',...
         'both' };
     
args = parse_args(pnames, dflts, varargin{:});

% check if valid es type
if ~isvalidstr(args.metric, valid_metric)
    error('Invalid metric: %s\n', args.metric);
end

if ~isempty(args.rank)
    args.rank = parse_gctx(args.rank);
elseif isempty(args.rank) && ~isempty(args.score)
    % compute ranks if not provided
    args.score = parse_gctx(args.score);
    args.rank = args.score;
    args.rank.mat = rankorder(args.score.mat, 'fixties', false,...
                              'direc', 'descend');
end

if isequal(args.metric, 'wtcs')
    args.score = parse_gctx(args.score);
    assert(isequal(args.rank.rid, args.score.rid));
    assert(isequal(args.rank.cid, args.score.cid));
end

isweighted = ismember(args.metric, {'wtcs'});

args.uptag = parse_geneset(args.uptag);
args.dntag = parse_geneset(args.dntag);

args.uptag = validate_geneset(args.uptag, args.rank.rid);
args.dntag = validate_geneset(args.dntag, args.rank.rid);

[scoreds, lfu_ds, lfd_ds] = compute_score(args.uptag, args.dntag, args.rank, isweighted, args.score, args.estail);

end

function [scoreds, lfu_ds, lfd_ds] =  compute_score(uptag, dntag, ds_rank, isweighted, ds_score, estail)
% Compute CMAP enrichment statistic
% score is 3-d matrix nc x nq x 3. The third dimension contains the up,
% down and combined scores in that order.

[numFeatures, numSamples] = size(ds_rank.mat);

rid_dict = list2dict(ds_rank.rid);
max_rank = length(ds_rank.rid);

upind = cellfun(@(x) cell2mat(rid_dict.values(x)), {uptag.entry},...
    'uniformoutput', false);
dnind = cellfun(@(x) cell2mat(rid_dict.values(x)), {dntag.entry},...
    'uniformoutput', false);

[score, leadf] = cmap_score_core(upind, dnind, ds_rank, ...
                              max_rank, isweighted, ds_score, estail);
% nq = length(upind);
% % numSamples x nq x [up, dn , combo]
% score = zeros(numSamples, nq, 3);
% 
% for ii=1:nq
%     [srt_up, srtidx_up] = sort(ds_rank.mat(upind{ii}, :), 1);
%     [srt_dn, srtidx_dn] = sort(ds_rank.mat(dnind{ii}, :), 1);
%     
%     if isweighted
%         up_esmax = fast_es_core(srt_up, max_rank, true,...
%             ds_score.mat(bsxfun(@plus, upind{ii}(srtidx_up), numFeatures*(0:numSamples-1))));
%         dn_esmax = fast_es_core(srt_dn, max_rank, true,...
%             ds_score.mat(bsxfun(@plus, dnind{ii}(srtidx_dn), numFeatures*(0:numSamples-1))));
%     else
%         up_esmax = fast_es_core(srt_up, max_rank, false, []);
%         dn_esmax = fast_es_core(srt_dn, max_rank, false, []);
%     end
%     
%     score(:, ii, 1) = up_esmax;
%     score(:, ii, 2) = dn_esmax;
%     
%     % Compute combined score
%     score(:, ii, 3) = getcombinedes(up_esmax, dn_esmax, false);    
% end

cid = regexprep(upper({uptag.head}'), '_UP$', '');
scoreds = mkgctstruct(score(:,:,3), 'rid', ds_rank.cid,...
    'cid', cid, 'rhd', ds_rank.chd,...
    'rdesc', ds_rank.cdesc, 'chd', {'desc'},...
    'cdesc', {uptag.desc}');
scoreds.up_score = score(:, :, 1);
scoreds.dn_score = score(:, :, 2);
scoreds.rank = rankorder(score(:,:,3), 'direc', 'descend', 'fixties', false);
scoreds.is_weighted = isweighted;

lfu_ds = mkgctstruct(leadf(:,:,1), 'rid', ds_rank.cid,...
    'cid', cid, 'rhd', ds_rank.chd,...
    'rdesc', ds_rank.cdesc, 'chd', {'desc'},...
    'cdesc', {uptag.desc}');

lfd_ds = mkgctstruct(leadf(:,:,2), 'rid', ds_rank.cid,...
    'cid', cid, 'rhd', ds_rank.chd,...
    'rdesc', ds_rank.cdesc, 'chd', {'desc'},...
    'cdesc', {uptag.desc}');

end