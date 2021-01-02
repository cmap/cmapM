function mkgct_duo(files,peaks,prop,fout)
% Wrapper for outputting peak calls
% bg
well = cell(length(files),1);
[domPeak,minPeak] = assignPeaks(peaks,prop);
for i =1 : length(files)
    tmp = files(i).name; 
    ix = find(tmp=='_');
    if ~isempty(ix)
        well{i} = tmp(ix(end)+1:find(tmp=='.')-1);
    else
         well{i} = tmp(1:find(tmp=='.')-1);
    end
end
analyte_id = cell(500,1);
for i = 1 : 500
    analyte_id{i} = horzcat('Analyte ',num2str(i));
end
fprintf(1,'%s\n',horzcat('Saving out file to ',fout));
mkgct0(horzcat(fout,'_major.gct'),domPeak,analyte_id,analyte_id,...
    well,4);
mkgct0(horzcat(fout,'_minor.gct'),minPeak,analyte_id,analyte_id,...
    well,4);