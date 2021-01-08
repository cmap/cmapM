function [peaks,prop] = buildDuo(files,fout,type,model)
% BUILDDUO  Main Routine for compiling dual tag data
%   [peaks,prop] = buildDuo(files,fout,type) will detect the dual peaks and
%   their support in each sample. 
%   Inputs: 
%       files : a data structure returned from dir(pwd,'*.lxb')
%       fout : the fullfile(pathname,filename) for the *.mat output
%       type : specifies log2 transformation, default = 'raw' or no trans.
%   Outputs: 
%       peaks : The detected peaks 2 x 500 x # files, i.e. the two detected
%       peaks across the 500 analytes for all files. 
%       prop : The mixing proportion, or support, for each detected peak.
%       Same dimension
% 
% see also filterSig, detect_peaks, fitmixture
% Author: Brian Geier, Broad 2010

spopen ; 

start = tic; 

if nargin < 3 % change to pass varargin argument
    type = 'log'; 
    model = 'direct'; 
end

num_files = length(files); 

peaks = zeros(2,500,num_files); 
prop = zeros(size(peaks)); 
failures = zeros(1,num_files); 
% First 50 analytes are control genes, i.e. single peak
for f = 1 : num_files
    fprintf(1,'%s\n',horzcat('Currently at file ',num2str(f))); tic; 
    data = parse_lxb(files(f).name); 
    if strcmp(type,'log2')
        data.RP1 = safelog2(data.RP1); 
    elseif strcmp(type,'log')
        data.RP1 = safelog(data.RP1); 
    end
        
    try
        [peaks,prop] = updateDetection(data.RP1,data.RID,peaks,prop,f,model); 
    catch em
        disp(em)
        failures(f) = 1; 
        fprintf(1,'%s\n',horzcat('Failed at file ',num2str(f))); 
        continue
    end
    fprintf(1,'%s\n',horzcat('File ',num2str(f),' took ',num2str(toc/60),...
        ' minutes.')); 
end

if nargin > 1
    try 
        save(horzcat(fout,'_',type),'peaks','prop','files','type','failures')
    catch em
        disp(em)
        save(fullfile(pwd,horzcat('tmp_',type)),'peaks','prop','files','type','failures')
    end
    fprintf(1,'%s\n',horzcat('Computation took ',num2str(toc(start)/60), ...
        ' minutes.')); 
end
end


function [peaks,prop] = updateDetection(RP1,RID,peaks,prop,f,type)


copyPeaks = zeros(size(peaks,1),size(peaks,2)); 
copyProp = zeros(size(copyPeaks)); 
switch type
    case 'gmmMatlab'
        parfor i = 1 : 50
            copyPeaks(:,i) = repmat(detect_peaks(RP1(RID==i),1) ,[2,1]) ;
        end
        parfor i = 51 : 500
            try
                if sum(RID==i) > 0
                    [copyPeaks(:,i),copyProp(:,i)] = detect_peaks(RP1(RID==i),2);
                end
            catch
                try
                    [copyPeaks(:,i),copyProp(:,i)] = detect_peaks(RP1(RID==i),2);
                catch
                    [copyPeaks(:,i),copyProp(:,i)] = detect_peaks(RP1(RID==i),2);
                end
            end
        end
    case 'direct'
        parfor i = 1 : 50
            copyPeaks(:,i) = repmat(median(RP1(RID==i)) ,[2,1]) ;
        end
        parfor i = 51 : 500
            if sum(RID==i) > 0
                sig = RP1(RID==i); 
                [copyPeaks(:,i),copyProp(:,i)] = fitmixture(filterSig(sig));
            end 
        end
    case 'gibbs'
        parfor i = 1 : 50
            copyPeaks(:,i) = repmat(median(RP1(RID==i)) ,[2,1]) ;
        end
        parfor i = 51 : 50        
            if sum(RID==i) > 0
                [copyPeaks(:,i),copyProp(:,i)] = fitmixture(RP1(RID==i),'gibbs');
            end
        end
end

peaks(:,:,f) = (copyPeaks) ; 
prop(:,:,f) = (copyProp); 

end

