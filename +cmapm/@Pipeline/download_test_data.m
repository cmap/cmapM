function download_test_data
% DOWNLOAD_TEST_DATA Download sample data for testing purposes

archive_url = 'https://s3.amazonaws.com/repo-assets.clue.io/cmap_pipeline_test_data_v1.tar.gz';
outpath = cmapmpath;
unpack_path = fullfile(outpath, 'test_data');
if exist(unpack_path, 'dir');
    fprintf(1, 'Path %s already exists skipping.\n', unpack_path);
else
    fprintf(1, 'Downloading testdata from %s...\n', archive_url);
    untar(archive_url, outpath);
    fprintf(1, 'Unpacked to %s\n', unpack_path);
end

end
