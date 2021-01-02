function mmap = memmap_dsbin(bin_file)
% MEMMAP_DSBIN Create memorymap of dataset binary
% MMAP = MEMMAP_DSBIN(BIN_FILE)

% Read header
fid = fopen(bin_file, 'r');
dim = fread(fid, 2, 'uint64');
fclose(fid);
header_length = 2*64/8;

% Create Memory map
mmap = memmapfile(bin_file, ...    
           'Offset', header_length,...
           'Format', {...
           'single', [dim(1), 1], 'Matrix'},...
           'Repeat', dim(2));
end