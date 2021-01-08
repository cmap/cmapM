function download_cmapm_assets
% DOWNLOAD_CMAPM_ASSETS Download assets for the CMapM repo
% Called automatically from SETUP_ENV

archive_url = 'https://assets.clue.io/cmapm/cmapm_assets_v2.0.tar.gz';
vdb_url = 'https://assets.clue.io/cmapm/cmap_vdb_lite_v1.0.tar.gz';

outpath = cmapmpath;
% download and extract tar
if ~isdirexist(fullfile(outpath, 'resources')) || ~isdirexist(fullfile(outpath, 'demo-datasets'))
    fprintf(1, 'First-time setup. Downloading demo-datasets and files, this might take a few minutes...\n');
    download_tar(archive_url, outpath, '.');
end
if ~isdirexist(fullfile(outpath, 'vdb'))
    fprintf(1, 'First-time setup. Downloading data dependencies, this might take a few minutes...\n');
    download_tar(vdb_url, outpath, 'vdb');
end


end
