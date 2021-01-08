function perm_stat = permute_stat(permzs)

ss = cell2mat(permzs.cdesc(:, permzs.cdict('sig_strength')));
cc_q75 = cell2mat(permzs.cdesc(:, permzs.cdict('cc_q75')));
q_ss = prctile(ss, [25,75]);
q_cc = prctile(cc_q75, [25,75]);
ss_cutoff = q_ss(2) + 1.5*(q_ss(2) - q_ss(1));
cc_cutoff = q_cc(2) + 1.5*(q_cc(2) - q_cc(1));
ss_cutoff(isnan(ss_cutoff)) = -666;
cc_cutoff(isnan(cc_cutoff)) = -666;
perm_stat = struct('sig_strength', {ss}, 'cc_q75', {cc_q75},...
            'ss_cutoff', ss_cutoff, 'cc_cutoff', cc_cutoff);
        
end