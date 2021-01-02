function figlist = savefigures(varargin)
% SAVEFIGURES Save currently open figures to disk.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

toolname = mfilename;
pnames = {'fmt', 'out' , 'mkdir', 'sortord', 'exclude',...
    'overwrite','lower', 'closefig', 'antialias','verbose'};
dflts = {'png', '.', true, true, [],...
    false, false, false, false, true};
args = parse_args(pnames,dflts,varargin{:});
[hf, ord] = setdiff(findobj('type', 'figure'), args.exclude);
% sorted by default
if ~args.sortord
    hf = hf(sort(ord));
end
nf = length(hf);
figlist=cell(nf,1);

%search these fields for a label
namefields = {'name', 'tag'};

%create sub folder by default
if args.mkdir
    wkdir = mkworkfolder(args.out, toolname);    
else
    wkdir = args.out;
end

dbg (args.verbose, 'Saving %d figure(s) to %s', nf, wkdir);

for ii=1:nf
    
    for jj=1:length(namefields);
        lbl = get(hf(ii), namefields{jj});
        if args.lower
            lbl = lower(lbl);
        end
        if ~isempty(lbl) 
            [isvalid, lbl]= validate_fname(lbl);
            break; 
        end
    end
    % try using the title of the current axis
    if isempty(lbl)
        figure(hf(ii))
	if args.antialias
	  myaa
	end
        s = get(get(gca, 'title'),'string');
        if args.lower
            s = lower(s);
        end
        if ~isempty(s)
            [isvalid, lbl] = validate_fname(strrep(s, ' ', '_'));            
        end
    end
    
    if isempty(lbl)
        lbl = sprintf('figure_%d',hf(ii));      
    end
    if args.overwrite
        figfile = sprintf('%s.%s',lbl,args.fmt);
    else        
        figfile = mkuniqfile(sprintf('%s.%s',lbl,args.fmt), wkdir);
    end
    figlist{ii} = fullfile(wkdir, figfile);
    
    dbg(args.verbose, '%s', figfile);
    
    saveas(hf(ii), figlist{ii});
    
end
if args.closefig
    close(hf);
end
