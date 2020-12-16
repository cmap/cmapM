function scratch(cmd, varargin)

pnames = {'prefix', 'path'};
dflts = {'myanalysis', fullfile(mortarpath, 'scratch')};
args = parse_args(pnames, dflts, varargin{:});
assert(ischar(cmd), 'CMD must be a string');
[fp, fn] = get_work_files(args.path);
if ~isdirexist(args.path)
    mkdir(args.path);
end
switch lower(cmd)
    case {'n', 'new'}
        mfile = sprintf('wk_%s.m', args.prefix);
        [~, fp] = mkuniqfile(mfile, args.path);
        edit(fp);
    case {'l', 'last'}        
        edit (fp{1});
    case {'e', 'edit', 'load', 'open'}
        if nargin>1
            fidx = strcmp(varargin{1}, fn);
            if ~isempty(fidx)
                edit (fp{fidx});
            else
                error('File not found: %s', varargin{1})
            end
        else            
            scratch('ls');            
            reply = input('Select file index:');
            if ~isempty(reply) && reply >0 && reply <= length(fp)                
                edit(fp{reply}); 
            end
        end
                
    case {'ls', 'list'}        
        for ii=1:length(fn)
            fprintf('%d\t%s\n', ii, fn{ii});
        end
        
    otherwise
        error('Unknown command: %s', cmd)
end

end

function [fp, fn] = get_work_files(wkpath)

d = dir(fullfile(wkpath, 'wk_*.m'));
[~, ts_idx] = sort([d.datenum], 'descend');
fn = {d(ts_idx).name}';
fp = strcat(wkpath, filesep, fn);

end