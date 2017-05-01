function figlist = savefigures(varargin)
% SAVEFIGURES Save currently open figures to disk.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

toolName = mfilename;
pnames = {'fmt', 'out' , 'mkdir', 'sortord', 'exclude',...
    'overwrite','lower', 'closefig','verbose'};
dflts = {'png', '.', true, true, [],...
    false, false, false, true};
arg = parse_args(pnames,dflts,varargin{:});
[hf, ord] = setdiff(findobj('type', 'figure'), arg.exclude);
% sorted by default
if ~arg.sortord
    hf = hf(sort(ord));
end
nf = length(hf);
figlist=cell(nf,1);

%search these fields for a label
namefields = {'name', 'tag'};

%create sub folder by default
if arg.mkdir
    wkdir = mkworkfolder(arg.out, toolName);
    
else
    wkdir = arg.out;
end
if arg.verbose
    fprintf ('Saving %d figure(s) to %s\n', nf, wkdir);
end
for ii=1:nf
    
    for jj=1:length(namefields);
        lbl = get(hf(ii), namefields{jj});
        if arg.lower
            lbl = lower(lbl);
        end
        if ~isempty(lbl) 
            [~, lbl]= validate_fname(lbl);
            break; 
        end
    end
    % try using the title of the current axis
    if isempty(lbl)
        figure(hf(ii))
        s = get(get(gca, 'title'),'string');
        if arg.lower
            s = lower(s);
        end
        if ~isempty(s)
            [~, lbl] = validate_fname(strrep(s, ' ', '_'));            
        end
    end
    
    if isempty(lbl)
        lbl = sprintf('figure_%d',hf(ii));      
    end
    if arg.overwrite
        figfile = sprintf('%s.%s',lbl,arg.fmt);
    else        
        figfile = mkuniqfile(sprintf('%s.%s',lbl,arg.fmt), wkdir);
    end
    figlist{ii} = fullfile(wkdir, figfile);
    if arg.verbose
        fprintf('%s\n',figfile);
    end
    saveas(hf(ii), figlist{ii});
    
end
if arg.closefig
    close(hf);
end
