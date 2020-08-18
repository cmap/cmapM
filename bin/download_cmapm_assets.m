function download_cmapm_assets
% DOWNLOAD_CMAPM_ASSETS Download assets for the CMapM repo
% Called automatically from SETUP_ENV

archive_url = 'https://s3.amazonaws.com/repo-assets.clue.io/cmapm_assets_v1.tar.gz';
outpath = cmapmpath;
% download and extract tar
download_tar(archive_url, outpath, 'resources');

end
