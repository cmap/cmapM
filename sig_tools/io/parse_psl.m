% Parse BLAT's psl output and return raw and hyperlink output (with scores and identity).

function [o,s] = parse_psl(fname, fieldprefix)

% fields
isrename = false;
if exist('fieldprefix', 'var')
    isrename = true;
    oldfn = {'SCORE', 'QSTART', 'QEND', 'QSIZE', 'IDENTITY', 'TNAME', 'STRAND', 'TSTART', 'TEND', 'SPAN'};
    newfn = strcat(fieldprefix, oldfn);
end

x = textread(fname,'%s','headerlines',5,'delimiter','\n');

nr=length(x);

for ii=1:nr
    a = textscan(x{ii},...
        '%d%d%d%d%d%d%d%d%s%s%d%d%d%s%d%d%d%d%s%s%s',...
        'delimiter','\t');
    
    [o.match(ii), o.mismatch(ii), o.repmatch(ii), o.n(ii),...
     o.qgapcount(ii), o.qgapbases(ii), o.tgapcount(ii), o.tgapbases(ii),...
     o.strand{ii}, o.qname{ii}, o.qsize(ii), o.qstart(ii),...
     o.qend(ii), o.tname{ii}, o.tsize(ii), o.tstart(ii),...
     o.tend(ii), o.blockcount(ii), o.blocksizes{ii}, o.qstarts{ii},...
     o.tstarts{ii}] = deal(a{:});
end

% match webblat results
s.QUERY = [o.qname{:}]';
s.SCORE = a2c(double(o.match) + double(o.repmatch)/2.0 - double(o.mismatch) - double(o.qgapcount) - double(o.tgapcount));
s.QSTART = a2c(o.qstart+1);
s.QEND = a2c(o.qend);
s.QSIZE = a2c(o.qsize);
% s.IDENTITY = a2c((100 * (o.match + o.repmatch -2*(o.qgapcount+o.tgapcount)) ./ (o.match+o.repmatch+o.mismatch)));
% match identity (cast to double)
s.IDENTITY = a2c((100 * double(o.match + o.repmatch - 2 * (o.qgapcount)) ./ double(o.match + o.repmatch + o.mismatch)));
s.TNAME = strrep([o.tname{:}]','chr','');
s.STRAND = [o.strand{:}]';
s.TSTART = a2c(o.tstart+1);
s.TEND = a2c(o.tend);
s.SPAN = a2c(o.tend - o.tstart +1);

% append fieldprefix if needed
if isrename
    s = renamefield(s, oldfn, newfn);
end

function y = a2c(x)
y = cellfun(@num2str,num2cell(x(:)),'uniformoutput',false);