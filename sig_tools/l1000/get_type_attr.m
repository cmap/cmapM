function [rgb, sym, isfilled] = get_type_attr(gp)
% Standardize colors and attributes for pert_types

 p = struct('pert_type', {'lma_x'; 'ctl_vector'; 'trt_poscon'; 'trt_poscon.es';...
                        'trt_cp'; 'trt_sh'; 'trt_oe'; ...
                        'trt_pep'; 'trt_cell'; '-666';...
                        'ctl_vehicle'}, ...
          'symbol', {'h'; 's'; 'h'; 'd';...
                     'o'; 'o'; 'o';...
                     'o'; 'o'; 'o';...
                     's'},...
          'color', {'grey'; 'lime'; 'orange'; 'purple';...
                    'blue'; 'purple'; 'scarlet';...
                    'ochre'; 'olive'; 'black';...
                    'olive'},...
          'isfilled', {0; 1; 1; 1;...
                     0; 0; 0;...
                     0; 0; 0;...
                     1});
                
dict = list2dict({p.pert_type});
[gn, gidx] = getcls(lower(gp));
ngp = length(gp);
col = cell(ngp, 1);
sym = cell(ngp, 1);
isfilled = false(ngp, 1);
col(:) = {p(dict('-666')).color};
sym(:) = {p(dict('-666')).symbol};

% non standard colors for ctl and trt
ctl_color = {'olive','lime','grey'};
ctl_idx=1;
trt_color = {'blue','forest','scarlet','ochre','black'};
trt_idx=1;

for ii=1:length(gn)
    this = gidx==ii;
    if dict.isKey(gn{ii})
        col(this) = {p(dict(gn{ii})).color};
        sym(this) = {p(dict(gn{ii})).symbol};
        isfilled(this) = p(dict(gn{ii})).isfilled;
    elseif rematch(gn(ii), '^ctl')
        col(this) = ctl_color(ctl_idx);
        sym(this) = {'s'};
        isfilled(this) = 1;
        ctl_idx = mod(ctl_idx, length(ctl_color)) + 1;
    else
        col(this) = trt_color(trt_idx);
        sym(this) = {'o'};
        isfilled(this) = 0;
        trt_idx = mod(trt_idx, length(trt_color)) + 1;        
    end
end

rgb = get_color(col);

end