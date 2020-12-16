classdef Chip
    
    % public properties
    properties (Constant=true)
        % Information on all chips
        chip_info_file = fullfile(mortarpath, 'resources', 'chip_info.yaml');
    end
    
    methods (Static=true)
        
        function res = chip_info(refresh_cache)
            % CHIP_INFO get infomation on all chips
            if isequal(nargin, 1)
                do_refresh = refresh_cache;
            else
                do_refresh = false;
            end
            persistent chip_info_;
            if isempty(chip_info_) || do_refresh
                chip_info_ = cellfun(@(x) cat(1,x),...
                    ReadYaml(mortar.common.Chip.chip_info_file,0,1,0),...
                    'unif', true)';
                
            end            
            res = chip_info_;
        end
        
        function [res, chip_file] = get_chip(chip_platform, chip_space, refresh_cache)
            % GET_CHIP Get information for specified platform and feature
            % space
            %   [R, F] = GET_CHIP(PLATFORM, SPACE)
            %   [R, F] = GET_CHIP(PLATFORM, SPACE, REFRESH_CACHE)
            %   Invalidates cache and reloads data
            persistent x;
            if nargin>0
                if ~(nargin>1)
                    dbg(1, 'Chip space not specified, defaulting to all')
                    chip_space = 'all';
                end
                if isequal(nargin, 3)
                    do_refresh = refresh_cache;
                else
                    do_refresh = false;
                end
                chip_info = mortar.common.Chip.chip_info(do_refresh);
                [is_valid_platform, chip_idx] = mortar.common.Chip.isValidPlatform_(chip_platform);
                assert(is_valid_platform, 'Invalid platform: %s', chip_platform);
                [is_valid_space, space_idx] = mortar.common.Chip.isValidSpace_(chip_platform, chip_space);
                if ~is_valid_space
                    msgid = sprintf('%s:InvalidSpace', mfilename);
                    valid_space = print_dlm_line(chip_info(chip_idx).space,'dlm', ',');
                    errmsg = sprintf('Invalid space "%s" for platform: %s, valid spaces are: %s', chip_space, chip_platform, valid_space);
                    dbg(1, errmsg);
                    error(msgid, errmsg);
                end
                if isempty(x) || do_refresh
                    x = mortar.containers.Dict();
                end
                chip_file = chip_info(chip_idx).file;
                if ~x.iskey(chip_platform)
                    x(chip_platform) = mortar.common.Chip.readChip_(chip_file);
                end
                this_chip = x(chip_platform);
                res = mortar.common.Chip.getChipSpace_(this_chip{1}, chip_platform, chip_space);
            else
                error('No chip file specified');
            end
        end
        
        function res = list_chip
            if nargout
                res = struct('chip_space', mortar.common.Chip.chip_spaces,...
                    'desc', mortar.common.Chip.chip_space_desc);
            else
                chip_info = mortar.common.Chip.chip_info;
                nplatform = length(chip_info);
                fprintf(1, 'platform\tchip_space\tdesc\n');
                for ii=1:nplatform
                    this_chip = chip_info(ii);
                    for jj=1:length(this_chip.space)
                        fprintf(1, '%s\t%s\t%s\n', this_chip.platform, this_chip.space{jj}, this_chip.desc{jj});
                    end
                end
            end
        end
        
    end
    
    methods (Static=true, Access=private)
        function res = readChip_(chip_file)
            res = parse_record(chip_file, 'detect_numeric', false);
        end
        
        function [tf, chip_idx] = isValidPlatform_(chip_platform)            
            cinfo = mortar.common.Chip.chip_info;
            match = strcmpi({cinfo.platform}, chip_platform);
            tf = any(match);
            chip_idx = find(match);
        end
        
        function [tf, space_idx] = isValidSpace_(chip_platform, chip_space)
            cinfo = mortar.common.Chip.chip_info;
            [is_platform, chip_idx] = mortar.common.Chip.isValidPlatform_(chip_platform);
            assert(is_platform, 'Invalid platform: %s', chip_platform);
            space_match = strcmpi(cinfo(chip_idx).space, chip_space);
            tf = any(space_match);
            space_idx = find(space_match);
        end
        
        function chip = getChipSpace_(chip, chip_platform, chip_space)
            switch(chip_platform)
                case 'l1000'
                    switch(chip_space)
                        case 'aig'
                        case 'bing'
                            % restrict to best inferred genes + LM
                            is_bing = strcmp({chip.pr_is_bing}', '1');
                            chip = chip(is_bing);
                        case 'lm'
                            % restrict to best inferred genes + LM
                            is_lm = strcmp({chip.pr_is_lm}', '1');
                            chip = chip(is_lm);
                        case 'aignolm'
                            is_not_lm = ~strcmp({chip.pr_is_lm}', '1');
                            chip = chip(is_not_lm);
                        case 'bingnolm'
                            % restrict to best inferred genes + LM
                            is_bing = strcmp({chip.pr_is_bing}', '1') ;
                            is_not_lm = ~strcmp({chip.pr_is_lm}', '1');
                            chip = chip(is_not_lm & is_bing);
                    end
                case 'affx_u133'
                    switch(chip_space)
                        case 'l1000'
                            % U133 probesets used in L1000
                            is_u133 = strcmp({chip.pr_is_inf}, '1');
                            chip = chip(is_u133);
                        case 'all'
                            % All U133 probesets
                    end
                case 'entrez'
                    switch (chip_space)
                        case 'all'
                    end
                    
                case 'ensembl'
                    switch (chip_space)
                        case 'all'
                    end
                case 'pr500_cs5'
                    switch(chip_space)
                        case 'all'
                            
                        otherwise
                            error('Unknown chip_space %s for platform %s', chip_space, chip_platform);
                    end
                    
                case 'l1000_covid'
                    switch(chip_space)
                        case 'aig'
                        case 'bing'
                            % restrict to best inferred genes + LM
                            is_bing = strcmp({chip.pr_is_bing}', '1');
                            chip = chip(is_bing);
                        case 'lm'
                            % restrict to best inferred genes + LM
                            is_lm = strcmp({chip.pr_is_lm}', '1');
                            chip = chip(is_lm);
                        case 'aignolm'
                            is_not_lm = ~strcmp({chip.pr_is_lm}', '1');
                            chip = chip(is_not_lm);
                        case 'bingnolm'
                            % restrict to best inferred genes + LM
                            is_bing = strcmp({chip.pr_is_bing}', '1') ;
                            is_not_lm = ~strcmp({chip.pr_is_lm}', '1');
                            chip = chip(is_not_lm & is_bing);
                    end
                otherwise
                    error('Unknown platform %s', chip_platform);
            end
        end
        
        function addProperties_(dict, name)
            s = cell2struct(dict.values', dict.keys);
            p = addprop(obj, name);
            p.Constant = true;
            obj.(name) = s;
        end
    end
end
