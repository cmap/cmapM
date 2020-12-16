function status = logger(logfile, appid, msg)
% LOGGER simple logger
%   LOGGER(LOGFILE, APPID, MSG) appends the application id and message
%   string MSG to LOGFILE.

fid = fopen(logfile, 'at');
fprintf(fid, '[%s]:%s:%s\n',datestr(now), appid, msg);
status = fclose(fid);

end