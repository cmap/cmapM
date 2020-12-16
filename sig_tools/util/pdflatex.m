% PDFLATEX Wrapper for pdflatex binary.
% PDFLATEX(TEXFILE) Runs pdflatex with TEXFILE as input.
%
% PDFLATEX(TEXFILE, 'PARAM1', val1, 'PARAM2', val2, ...) specifies optional
% parameter name/value pairs.
%
% '-cleanup'        boolean [true, (false)]
% '-pdflatex_bin'   string ['/path/to/pdflatex']. Defaults:
%                   /usr/bin/pdflatex (Unix), /sw/bin/pdflatex (Mac)
% '-bibtex_bin'     string ['/path/to/bibtex']. Defaults:
%                   /usr/bin/bibtex (Unix), /sw/bin/bibtex (Mac)
%
% Note: pdflatex must be installed on the system.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

function pdflatex(texfile, varargin)

pnames = {'cleanup','pdflatex_bin', 'bibtex_bin', 'verbose'};
dflts = {false, '', '', false};
arg = parse_args(pnames, dflts, varargin{:});

% path to pdflatex and bibtex binaries
if ~isempty(arg.pdflatex_bin)
    if isfileexist(arg.pdflatex_bin)
        pdflatex_bin = arg.pdflatex_bin;
    else
        error('pdflatex not found at:%s', arg.pdflatex_bin)
    end
elseif ismac
    [pdflatex_bin, exit_code] = find_binary('pdflatex');    
    if exit_code>0
        testdir = {'/usr/texbin/pdflatex', '/sw/bin/pdflatex', '/Library/TeX/texbin/pdflatex'};
        for ii=1:length(testdir)
            if isfileexist(testdir{ii})
                pdflatex_bin = testdir{ii};
            end
        end
    end
elseif isunix
    [pdflatex_bin, exit_code] = find_binary('pdflatex');
    if exit_code>0
        pdflatex_bin = '/usr/bin/pdflatex';
    end
end

if ~isempty(arg.bibtex_bin)
    if isfileexist(arg.bibtex_bin)
        bibtex_bin = arg.bibtex_bin;
    else
        error('bibtex not found at:%s', arg.bibtex_bin)
    end
elseif ismac
    [bibtex_bin, exit_code] = find_binary('bibtex');    
    if exit_code>0
        testdir = {'/usr/texbin/bibtex', '/sw/bin/bibtex', '/Library/TeX/texbin/bibtex'};
        for ii=1:length(testdir)
            if isfileexist(testdir{ii})
                bibtex_bin = testdir{ii};
            end
        end
    end
elseif isunix
    [bibtex_bin, exit_code] = find_binary('bibtex');
    if exit_code>0
        bibtex_bin = '/usr/bin/bibtex';
    end
end

if ~isfileexist(pdflatex_bin)
    error ('pdflatex not found at:%s', pdflatex_bin);
end

if ~isfileexist(bibtex_bin)
    error ('bibtex not found at:%s', bibtex_bin);
end


if exist('texfile','var') && isfileexist(texfile)
    [filepath, file, ext]=fileparts(texfile);
    currdir = pwd;
    if isempty(filepath)
        filepath=currdir;
    end
    
    cd(filepath);
    if arg.verbose
        latexcmd = sprintf ('%s "%s" -output-directory="%s"', pdflatex_bin, file, filepath);
    else
        latexcmd = sprintf ('%s -interaction=batchmode "%s" -output-directory="%s"', pdflatex_bin, file, filepath);
    end
    bibtexcmd = sprintf ('%s "%s" ', bibtex_bin, file, filepath);
    system(latexcmd);
    system(bibtexcmd);
    system(latexcmd);
    system(latexcmd);
    
    cd(currdir);
    
    if arg.cleanup
        cleanup_tex(texfile);
    end
end
