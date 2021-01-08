function plot_spots(varargin)
% PLOT_SPOTS   Plot feature dye ROIs 
%   PLOT_SPOTS(varargin) will image a selection of dye ROIs 
%   Inputs: 
%       varargin
%           '-gpr': The data to infer, *.gct or *.mat
%           '-jpg': The dependency matrix to make inference, *.gct
%           '-out': The output directory
%           '-grp': The *.grp file specifying the dependent genes
%           '-block_size': The *.grp file specifying the landmark genes
%   Outputs: 
%       For each feature dye specified in the *grp file, an image of the
%       neighborhood is saved. The '-block_size' specifies the size of the
%       neighborhood. 
%   See also imagesc, gprread
% 
% Author: Brian Geier, Broad 2010

dflt_out = get_lsf_submit_dir ; 

toolName = mfilename ; 
pnames = {'-gpr','-jpg','-grp','-out','-block_size'};

dflts = {'','','',dflt_out,15};

arg = parse_args(pnames,dflts,varargin{:}); 

print_args(toolName,1,arg); 

otherwkdir = mkworkfolder(arg.out, toolName); 
fprintf('Saving analysis to %s\n',otherwkdir); 
fid = fopen(fullfile(otherwkdir,sprintf('%s_params.txt',toolName)),'wt'); 
print_args(toolName,fid,arg); 
fclose(fid); 
mkdir(otherwkdir,'snap_shots');

gpr_struct = gprread(arg.gpr);

view = imread(arg.jpg); % full scale image

rois = parse_grp(arg.grp); % dye features to view

xcoord = (gpr_struct.Data(:,1)-gpr_struct.Header.JpegOrigin(1))/gpr_struct.Header.PixelSize ;
ycoord = (gpr_struct.Data(:,2)-gpr_struct.Header.JpegOrigin(2))/gpr_struct.Header.PixelSize ;

dye_features = cell(size(gpr_struct.IDs));
for i = 1 : length(dye_features)
    tmp = gpr_struct.IDs{i};
    ix1 = find(gpr_struct.IDs{i}=='-');
    ix2 = find(gpr_struct.IDs{i}==' ');
    if isempty(ix1)
        dye_features{i} = 'empty';
        continue
    end
    dye_features{i} = tmp(ix1(2)+1:ix2(1)-1);
end

[~,rois_idx] = intersect_ord(dye_features,rois);

h = findNewHandle() ; 

for i = 1 : length(rois_idx)
%     figure
    x_pixels = xcoord(rois_idx(i))-arg.block_size:xcoord(rois_idx(i))+arg.block_size; 
    y_pixels = ycoord(rois_idx(i))-arg.block_size:ycoord(rois_idx(i))+arg.block_size;
    x_pixels(x_pixels<=0) = [];
    y_pixels(y_pixels<=0) = [];
    figure(h)
    imagesc(view(y_pixels,x_pixels,:))
    axis off ; 
    title(rois{i},'FontSize',14)
    saveas(h,fullfile(otherwkdir,'snap_shots',rois{i}),'png');
end
try
    close(h); 
catch err
    disp(err);
    close all ; 
end

