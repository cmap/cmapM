function mkconfigyaml(outfile, args)
% MKCONFIGYAML Create a config file in YAML format.
% MKCONFIGYAML(OUTFILE, CFG) Writes data in the CFG structure 
% to OUTFILE in YAML format

fn = fieldnames(args);
isfds = structfun(@(x) isds(x), args);
isfcell = structfun(@(x) iscell(x), args);

if any(isfds)
    tochange = fn(isfds);
    for ii=1:numel(tochange)
        args.(tochange{ii}) = stringify(args.(tochange{ii}));
    end        
end

if any(isfcell)
    tochange = fn(isfcell);
    for ii=1:numel(tochange)
        val = args.(tochange{ii});
        nval = numel(val);
        if numel(val)>10
            new_val = sprintf('%s...(%d)',...
                print_dlm_line(val(1:10), 'dlm', ','), nval);
        else
            new_val = print_dlm_line(val, 'dlm', ',');
        end
    end
        args.(tochange{ii}) = new_val;
end

WriteYaml(outfile, args);

end