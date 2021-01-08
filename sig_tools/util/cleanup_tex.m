% CLEANUP_TEX Delete LaTeX auxilliary files generated during processing.
% CLEANUP_TEX(TEXFILE)

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT
function cleanup_tex(texfile)

[p,f,e] =  fileparts(texfile);
ext = {'log','aux','bbl','lof','toc','lot','blg','out','nav','snm'};
ne = length(ext);

for ii=1:ne
    srch = fullfile(p, sprintf('%s.%s', f, ext{ii}));
    d = dir(srch);
    fn = {d.name}';    
    if ~isempty(fn)        
        for jj=1:length(fn)
            delete(fullfile(p,fn{jj}))
        end
    end
end
