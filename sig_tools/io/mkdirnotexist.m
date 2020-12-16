function dir_path = mkdirnotexist(dir_path)
% MKDIRNOTEXIST Create directory if it doesnt already exist
% P = MKDIRNOTEXIST(DP)

if ~isdirexist(dir_path)
    mkdir(dir_path)
end

end