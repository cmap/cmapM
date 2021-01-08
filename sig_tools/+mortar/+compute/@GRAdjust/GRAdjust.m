classdef GRAdjust
% Algorithms to adjust for Cell growth

    methods (Static=true)
        % Apply GR adjustment using T0 measurements
        [ds_gr, ds_gr_ctl] = ComputeGRWithT0(ds_treat, ds_ctl, ds_t0, min_lfc_ctl, max_lfc_ctl, p);
        
        % Apply GR adjustment using pre-computed Td
        [ds_gr, ds_lfc_double] = ComputeGRWithTd(ds_treat, ds_ctl, tbl_td, t, min_dbl, max_dbl);
        
    end % methods block

end
