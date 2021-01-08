function ds = parse_cxt(fname)
% PARSE_CXT Parse CXT files.
%   DS = PARSE_CXT(FNAME)

if isfileexist(fname)    
    if ~isempty(regexpi(fname, '.gz$', 'once'))
        isgz = true;
        %         fid = java.io.BufferedReader(...
        %         java.io.InputStreamReader(...
        %         java.util.zip.GZIPInputStream(...
        %         java.io.FileInputStream(fname)...
        %         )...
        %         )...
        %         );
        lines = parse_gz(fname);
    else
        isgz = false;
        %         fid = fopen(fname, 'rt');
        lines = parse_lines(fname);
    end
       
    % read headers
    [hd, lastidx] = get_header(lines);

    % name check
    [~, f]=fileparts(fname);
    ext_name = regexprep(f,'\.CXT','','ignorecase');
    int_name = regexprep(hd.NAME,'\.CEL$','','ignorecase');
    int_name = regexprep(int_name,'\.CEL\.gz$','','ignorecase');
    if ~isequal(int_name, ext_name)
        disp(int_name);
        disp(ext_name);
        error('Name check error')
    end
    nr = str2double(hd.NUM_FEATURES);
    
    % column header line
    tok = tokenize(lines{lastidx}, char(9), true);
    expidx = find(strcmpi('MAS5', tok));
    ridx = strcmpi('NAME', tok);
    rhidx = find(strcmpi('pcalls', tok));
    
    % pre-allocate space
    ds = struct('rid',{cell(nr, 1)},...
        'rhd', {{'pcalls'}},...
        'rdesc', {cell(nr, length(rhidx))},...
        'cid', ext_name,...
        'chd', {{'array','num_features'}},...
        'cdesc', {{hd.CHIP, hd.NUM_FEATURES}},...
        'mat', zeros(nr, 1));
    
    nl = length(lines)-lastidx;
    if nr > nl
         error('%d rows expected, found %d', nr, nl)
    end
    
    if ~isempty(expidx)    
    
    for ii=1:nr
        lidx = ii + lastidx;
        if ~isempty(lines{lidx})
%             tok = tokenize(lines{lidx}, char(9), true);
            tok = textscan(lines{lidx}, '%s\t%f\t%s');
            ds.rid(ii) = tok{ridx};
            ds.rdesc(ii, :) = tok{rhidx};
%             ds.mat(ii) = str2double(tok{expidx});
            ds.mat(ii) = tok{expidx};
%             line = get_line(fid, isgz);
        else
            error('%d rows expected, found %d', nr, ii)
        end
    end
    else
        error('MAS5 column not found')
    end
    
    ds.rdict = list2dict(ds.rhd);
    ds.cdict = list2dict(ds.chd);
    
else
    error('File not found: %s', fname)
end


end


function [hd, lastidx] = get_header(lines)
restr={'^#(NAME): (.*)';...
    '^#(NUM_FEATURES): (.*)';...
    '^#(CHIP): (.*)'};
nre = length(restr);
hd = struct('NAME','',...
    'NUM_FEATURES','',...
    'CHIP','');
lastidx = 1;
for jj=1:length(lines)
    if strncmp('#', lines{jj}, 1)
        for ii=1:nre
            tok = regexp(lines{jj}, restr{ii}, 'tokens', 'once');
            if length(tok)==2
                hd.(tok{1}) = strtrim(tok{2});
            end
        end
    else
        lastidx = jj;
        break
    end
end
end

function [hd, l] = get_header0(fid, isgz)
restr={'^#(NAME): (.*)';...
    '^#(NUM_FEATURES): (.*)';...
    '^#(CHIP): (.*)'};
nre = length(restr);
hd = struct('NAME','',...
    'NUM_FEATURES','',...
    'CHIP','');
l = get_line(fid, isgz);
while ~isempty(l) && strncmp('#', l, 1)
    for ii=1:nre
        tok = regexp(l, restr{ii}, 'tokens', 'once');
        if length(tok)==2
            hd.(tok{1}) = tok{2};
        end
    end
    l = get_line(fid, isgz);
end
end

function l = get_line0(fid, isgz)
if isgz
    l = strtrim(char(fid.readLine()));
else
    try
    l = fgetl(fid);
    if ~isequal(l, -1)
        l = strtrim(l);
    else
        l = '';
    end
    catch e
        disp(l);
    end
end
end