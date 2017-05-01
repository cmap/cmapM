function download_tar(url, root_dir, folder_name)
% DOWNLOAD_TAR Download and extracts a TAR archive file
% DOWNLOAD_TAR(URL, UNPACK_PATH) Downloads a TAR from URL and unpacks to
% UNPACK_PATH

unpack_path = fullfile(root_dir, folder_name);

if exist(unpack_path, 'dir');
    fprintf(1, 'Path %s already exists skipping.\n', unpack_path);
else
    fprintf(1, 'Downloading archive from %s...\n', url);
    untar(url, root_dir);
    fprintf(1, 'Unpacked to %s\n', unpack_path);
end

end