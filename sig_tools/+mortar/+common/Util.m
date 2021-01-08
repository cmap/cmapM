classdef Util
    % Utilities
    % Deprecated, use mortar.util.* instead
    methods (Static=true)
        
        function tf = isNumericType(t)
            % Check if input matches a numeric type.
            num_type = {'double', 'single', 'int8', ...
                'uint8', 'int16', 'uint16',...
                'int32', 'uint32', 'int64', ...
                'uint64', 'logical'};
            
            if iscell(t)
                tf = cell2mat(cellfun(@(x) ismember(x, num_type),...
                              t, 'uniformoutput', false));
            else
                tf = ismember(t, num_type);
            end
        end

        function yn = is1d(src)
            % Check if input array is one-dimensional.            
            yn = isequal(length(src), numel(src));
        end
        
        function lbl = genLabels(varargin)
            % GEN_LABEL Generate labels           
            s = struct('name',...
                        {'n'; '--zeropad'; '--prefix'; '--suffix'},...
                       'default',...
                        {[]; true; ''; ''});
            p = mortar.common.ArgParse('gen_label');
            p.add(s);

            args = p.parse(varargin{:});
            if length(args.n)>1
                seq = args.n;
            else
                if args.n>0
                    seq = 1:args.n;
                else
                    error ('N should be > 0');
                end
            end
            
            if args.zeropad
                maxdigits = floor(log10(max(seq)))+1;
                fmt = sprintf('%s%%.%dd%s', args.prefix, maxdigits, args.suffix);
            else
                fmt = sprintf('%s%%d%s', args.prefix, args.suffix);
            end
            
            lbl = cell(length(seq), 1);
            for ii=1:length(seq)
                lbl{ii, 1} = sprintf(fmt, seq(ii));
            end
        end
        
        function vn = validateVar(n, rep)
            % VALIDATEVAR check for valid matlab variable name.
            %   VN = VALIDATEVAR(N) Checks if N is a valid matlab variable and removes
            %   invalid chars from the name.
            %
            %   VN = VALIDATEVAR(N, REP) replaces invalid characters with REP instead of
            %   removing them.
                        
            if (~exist('rep', 'var'))
                rep='';
            end
            
            if iscell(n)
                numv = length(n);
            else
                n={n};
                numv=1;
            end
            
            vn = cell(numv,1);
            
            for ii=1:numv
                if ~isempty(n{ii})
                    %first char
                    v1 = regexprep(n{ii}(1),...
                        ['(%|&|{|}|\s|+|-|!|@|#|\$|\^|*|\(|\)|=|\[|\]|',...
                         '\\|;|:|~|`|,|\.|<|>|?|/|_|"|\|\x22|\x27|\x7c)'],...
                         rep);
                    % first char cannot be a number
                    v1 = regexprep(v1, sprintf('(^[0-9%s])', rep),'n$1');
                    
                    vrest = regexprep(n{ii}(2:end),...
                            ['(%|&|{|}|\s|+|-|!|@|#|\$|\^|*|\(|\)|=|\[|\]|',...
                            '\\|;|:|~|`|,|\.|<|>|?|/|"|\|\x22|\x27|\x7c)'],...
                            rep);
                    % remove contiguous replacements
                    vn{ii} = regexprep(strsqueeze([v1,vrest], rep),...
                                       [rep,'$'],'');
                else
                    vn{ii} = sprintf('VAR_%d',ii);
                end
            end
        end
        
        function [dup, dup_idx, freq] = FindDuplicate(list)
            % find duplicates in a list
            dup = {};
            dup_idx = [];
            freq = [];
            
            n = length(list);
            dict = containers.Map(list, 1:n);
            if ~isequal(n, dict.Count)
                ind = ~ismember(1:n, cell2mat(dict.values(dict.keys)));
                dup = list(ind);
                if nargout>1
                    % find indices
                    ndup = length(dup);
                    dup_idx = cell(ndup, 1);
                    for ii=1:ndup
                        dup_idx{ii} = find(cellfun(@(x) x==dup{ii}, list));
                    end
                end
                if nargout>2
                    % counts
                    freq = cellfun(@length, dup_idx);
                end
            end
        end
        
        function [desc, numeric] = detect_numeric(desc)
            % detect numeric fields and convert them            
            nanidx = strcmpi('NaN', desc);
            desc(nanidx) = {'-666'};
            [nr, nc] = size(desc);
            numeric = false(nc, 1);
            if nr>0
                % sample 10% of the rows to determine the type
                isnum = find(all(~isnan(str2double(strrep(desc(...
                    randsample(nr, floor(nr/20)+1), :), ',', ', '))), 1));
                numeric(isnum) = true;
                if any(isnum)
                    newdesc = num2cell(str2double(desc(:, isnum)));
                    % check if conversion is valid, revert to original if not
                    nancel = cell2mat(cellfun(@(x) any(isnan(x)), newdesc,...
                        'uniformoutput', false));
                    [~, ic] = find(nancel);
                    not_numeric = unique(ic);
                    newdesc(:, not_numeric) = desc(:, isnum(not_numeric));
                    
                    desc(:, isnum) = newdesc;
                    numeric(not_numeric) = false;
                end
                desc(nanidx) = {NaN};
            end
        end
        
        function addJar(jarlist, jarpath, isverbose)
            % ADDJAR Add Java archives to the class path.
            if ischar(jarlist)
                jarlist = {jarlist};
            end
            jcp = javaclasspath('-dynamic');
            for ii=1:length(jarlist)
                thisjar = fullfile(jarpath, jarlist{ii});
                if ~any(strcmp(thisjar, jcp)) && ~any(strcmp(fullfile(pwd, thisjar), jcp))
                    if isverbose
                        fprintf(1, 'Adding %s to classpath', thisjar);
                    end
                    javaaddpath(thisjar)
                end
            end
        end        
        
    end
    
end