classdef SigStrength
% Algorithms to signature strength

    methods(Static=true)
        
        % Signature strength based on number of induced features
        [ntot, nup, ndn] = ssNgene(x, varargin);
        
        % Signature strength based on mean difference of extreme scores
        ss = ssDifference(x, varargin);
        
        % Transcriptional activity scorebased on ss_diff
        res = tas_diff(ss_diff, cc_q75, nrep, use_absolute_scale);
        
        % Transcriptional activity score based on ss_ngene
        res = tas_ngene(ss_ngene, cc_q75, nrep, use_absolute_scale);
        
        % Adjust modzs by number of replicates
        zs = adjustZscore(zs, nrep);
        
        % Compute TAS values for a L-build
        rpt = computeTASFromBuild(sig_info_file, modz_file);
        
        % Compute cell inhibition scores for PRISM viability data
        rpt = computeCISFromBuild(sig_info_file, modz_file);
        res = cis(ss, cc_q75, nrep, use_absolute_scale);
        
        % compute replicate statistics
        rpt = replicateStats(varargin);
        
    end % Static methods block
       
end
