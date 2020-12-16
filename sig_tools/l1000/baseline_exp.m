function stats = baseline_exp(glist, cell_id, varargin)
% BASELINE_EXP Get baseline expression of genes in one cell line.

pnames = {'exp_file', ...
    'pcall_file',...
    'use_pcall',...
    'chip',...
    'ann_path'    
    };
dflts = {fullfile(get_l1k_path('cline_path'), 'cline_gene_n1515x12716.gctx'),...
    '',...
    false,...
    '',...
    ''};
args = parse_args(pnames, dflts, varargin{:});

if ischar(glist)
    glist = {glist};
end
glist = glist(:);

if ischar(cell_id)
    cell_id = {cell_id};
end
cell_id  = cell_id(:);

ng = length(glist);
nc = length(cell_id);
if nc>1 && ng==1
    glist = glist(ones(nc, 1));
elseif nc==1 && ng>1
    cell_id = cell_id(ones(ng, 1));
elseif ~isequal(ng, nc)
    error('Invalid input');
end

dsexp = parse_gctx(args.exp_file);

cell_lut = list2dict(dsexp.cid);
gs_lut = list2dict(dsexp.rid);

has_affx = gs_lut.isKey(glist) & cell_lut.isKey(cell_id);

base_exp = -666*ones(ng, 1);
if any(has_affx)
    ridx = cell2mat(gs_lut.values(glist(has_affx)));
    cidx = cell2mat(cell_lut.values(cell_id(has_affx)));
    ind = sub2ind(size(dsexp.mat), ridx, cidx);
    base_exp(has_affx, 1) = dsexp.mat(ind);
end

stats = struct('pr_gene_symbol', glist,...
    'cell_id', cell_id,...
    'base_exp', num2cell(base_exp));
    

% if args.use_pcall
%     dspcall = parse_gctx(args.pcall_file);
% else
%     stats = rmfield(stats, {'pr_pcall','best_pcall'});
% end
% if isempty(args.chip)
%     ps = genesym2ps(glist, 'ignore_missing', true);
% else
%     ps = genesym2ps(glist, 'ignore_missing', true, 'chip', args.chip, 'ann_path', args.ann_path);
% end
% rid_lut = list2dict(dsexp.rid);

% for ii=1:ng
%     tok = tokenize(ps{ii}, ' /// ');
%     if ~isempty(tok{1})
%         ridx = cell2mat(rid_lut.values(tok));        
%         this_exp = dsexp.mat(ridx, cidx);
%         if args.use_pcall
%             this_pcall = dspcall.mat(ridx, cidx);
%             
%             if any(this_pcall > -1)
%                 % pick best probeset based on pcall and expression
%                 x = (this_pcall>-1) .* this_exp;
%             else
%                 % pick by expression alone
%                 x = this_exp;
%             end
%             [srt_exp, best_idx ] = sort(x, 'descend');
%             stats(ii).best_pcall = this_pcall(best_idx(1));
%             stats(ii).pr_pcall = print_dlm_line(this_pcall(best_idx), 'dlm', ',');            
%         else
%             [srt_exp, best_idx ] = sort(this_exp, 'descend');
%         end
%         stats(ii).best_exp = this_exp(best_idx(1));        
%         stats(ii).best_ps = tok{best_idx(1)};
%         stats(ii).pr_id = print_dlm_line(tok(best_idx), 'dlm', ',');
%         stats(ii).pr_exp = print_dlm_line(this_exp(best_idx), 'dlm', ',', 'precision', 2);        
%     end
% end

end