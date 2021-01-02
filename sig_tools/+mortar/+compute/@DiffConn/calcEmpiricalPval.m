function res = calcEmpiricalPval(obs_a, obs_b, pop_a, pop_b, id_obs,...
                                   id_pop_a, id_pop_b, varargin)
% calcEmpiricalPval Compute empirical P-value for diff conn results
%   res = calcEmpiricalPval(obs_a, obs_b, pop_a, pop_b, id_obs,...
%                                   id_pop_a, id_pop_b, varargin)
% obs_a : Tau scores of the positive class 
% obs_b : Tau scores of the negative class
% pop_a : Tau scores of positive population
% pop_b : Tau scores of negative population
% id_obs : Cell array of strings, Ids corresponding to obs_a and obs_b
% id_pop_a : Cell array of strings, Ids corresponding to pop_a
% id_pop_b : Cell array of strings, Ids corresponding to pop_b
% nperm : integer, Number of random samplings from pop_a and pop_b. Default is 10000
% strat_gain_th : float, Threshold for computing stratified gain. Default is 85
% use_sum : Logical, If true compute sum of a and b instead of the
%           difference. Default is false

config = struct('name', {'--nperm';'--strat_gain_th';'--use_sum'},...
    'default', {10000; 85; false},...
    'help', {'Number of permutations'; 'Threshold for stratified gain statistic';
    'Use sum instead of difference for gain';});
opt = struct('prog', mfilename, 'desc', 'Compute empirical P-value');

[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

%   random sampling between a and b populations
num_pop_a = length(pop_a);
num_pop_b = length(pop_b);
   
%  Random sample stats
a_samp_idx = randsample(num_pop_a, args.nperm, true);
b_samp_idx = randsample(num_pop_b, args.nperm, true);

% exclude any samples with matched ids
keep_samp = ~strcmp(id_pop_a(a_samp_idx), id_pop_b(b_samp_idx));
a_samp = pop_a(a_samp_idx(keep_samp));
b_samp = pop_b(b_samp_idx(keep_samp));
 
if (args.use_sum)
    % compute sum of a and b instead of diff
    obs_b = -obs_b;
    b_samp = -b_samp;
    % to invert b scores in the output
    b_coef = -1;
else 
    b_coef = 1;
end

% Compute delta and gain for random samples
delta_rnd = abs(a_samp - b_samp);
gain_strat_rnd = mortar.compute.DiffConn.computeGainStratified(a_samp, b_samp, args.strat_gain_th);
gain_rnd = mortar.compute.DiffConn.computeGain(a_samp, b_samp);
   
% Observed sample stat
delta_obs = abs(obs_a - obs_b);
gain_strat_obs = mortar.compute.DiffConn.computeGainStratified(obs_a, obs_b, args.strat_gain_th);
gain_obs = mortar.compute.DiffConn.computeGain(obs_a, obs_b);
   
% Lookup empirical p-values
pval_delta = getEmpiricalFraction(delta_obs, delta_rnd);
pval_gain = getEmpiricalFraction(gain_obs, gain_rnd);
pval_gain_strat = getEmpiricalFraction(gain_strat_obs, gain_strat_rnd);

res = struct('id', id_obs,...
             'obs_a', num2cell(obs_a),...
             'obs_b', num2cell(b_coef*obs_b),...
             'delta', num2cell(delta_obs),...
             'gain', num2cell(gain_obs),...
             'gain_strat', num2cell(gain_strat_obs),...
             'pval_delta', num2cell(pval_delta),...
             'pval_gain', num2cell(pval_gain),...
             'pval_gain_strat', num2cell(pval_gain_strat));

end

function f = getEmpiricalFraction(v_list, pop_list)
% getEmpiricalFraction Fraction of values in a population that
% exceed an observed value.
% F = getEmpiricalFraction(V_LIST, POP_LIST)
% F is an array of length(v_list)
f = sum(bsxfun(@gt, pop_list(:)', v_list(:)),2)/length(pop_list);
end
