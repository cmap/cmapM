function download_cmapm_assets
% DOWNLOAD_CMAPM_ASSETS Download assets for the CMapM repo
% Called automatically from SETUP_ENV

archive_path = 'https://s3.amazonaws.com/repo-assets.clue.io/';
archive_name = 'cmapm_assets_v1.tar.gz';
url = fullfile(archive_path, archive_name);
outpath = cmapmpath;
% download and extract tar
download_tar(url, outpath, 'resources');

end