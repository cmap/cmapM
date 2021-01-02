classdef Spaces
    
    % public properties
    properties (Constant=true)
        
        % L1000 probe spaces
        % maps space name to file_path relative to vdbpath
        probe_space = mortar.containers.Dict({
            'aig';...
            'bing';...
            'lm';...
            'full_probeset';...
            'lm_probeset';...
            'lm_epsilon_probeset';...
            'bing_probeset';...
            'bing_v1_probeset'},...
            {'spaces/aig_gene_ids_n12328.grp';...
            'spaces/bingv2_gene_ids_n10174.grp';...
            'spaces/lm_epsilon_gene_ids_n978.grp';...
            '/cmap/data/build/a2y13q1/rid_n22268.grp';...
            'spaces/lm_epsilon_n978.grp';...
            'spaces/lm_epsilon_n978.grp';...
            'spaces/bingv2_n10174.grp';...
            'spaces/bing_n10638.grp'});
        
        % Signature spaces
        % maps space name to file_path relative to vdbpath
        sig_space = mortar.containers.Dict({'summly';....
                                            'summly_ts';...
                                            'touchstone'},...
            {'summly/sigspace_n69761.grp';...
            'summly/tsspace_n63610.grp';...
            'touchstone/touchstone.grp'});
        
        % Cell line spaces
        % maps space name to file_path relative to vdbpath
        cell_space = mortar.containers.Dict({'lincs_core'},...
            {'cline/lincs_core_lines.grp'});

        % Pert type spaces
        % maps space name to file_path relative to vdbpath
        pert_type_space = mortar.containers.Dict({'digest'},...
            {'pert_info/pert_type_digest.grp'});
        
    end
    
    methods (Static=true)
        
        function res = probe(varargin)
            persistent x;
            if nargin>0
                space = varargin{1};
                if isempty(x)
                    x = mortar.containers.Dict();
                end
                if ~x.iskey(space)
                    space_file = fullfile(vdbpath, mortar.common.Spaces.probe_space(space));
                    x(space) = mortar.common.Spaces.readList_(space_file{1});
                end
                res = x(space);
                res = res{1};
            else
                res = mortar.common.Spaces.list_probe;
            end
        end
        
        function res = list_probe
            res = mortar.common.Spaces.probe_space.keys();
        end
        
        function res = sig(space)
            persistent x;
            if isempty(x)
                x = mortar.containers.Dict();
            end
            if ~x.iskey(space)
                space_file = fullfile(vdbpath, mortar.common.Spaces.sig_space(space));
                x(space) = mortar.common.Spaces.readList_(space_file{1});
            end
            res = x(space);
            res = res{1};
        end
        
        function res = cell(space)
            persistent x;
            if isempty(x)
                x = mortar.containers.Dict();
            end
            if ~x.iskey(space)
                space_file = fullfile(vdbpath, mortar.common.Spaces.cell_space(space));
                x(space) = mortar.common.Spaces.readList_(space_file{1});
            end
            res = x(space);
            res = res{1};
        end
        
        function res = list_cell
            res = mortar.common.Spaces.cell_space.keys();
        end

        function res = pert_type(space)
            persistent x;
            if isempty(x)
                x = mortar.containers.Dict();
            end
            if ~x.iskey(space)
                space_file = fullfile(vdbpath, mortar.common.Spaces.pert_type_space(space));
                x(space) = mortar.common.Spaces.readList_(space_file{1});
            end
            res = x(space);
            res = res{1};
        end
   
        function res = list_pert_type
            res = mortar.common.Spaces.pert_type_space.keys();
        end
    end
    
    methods (Static=true, Access=private)
        function res = readList_(space_file)            
            res = mortar.containers.List(space_file);
        end
        
        function addProperties_(dict, name)
            s = cell2struct(dict.values', dict.keys);
            p = addprop(obj, name);
            p.Constant = true;
            obj.(name) = s;
        end
    end
end
