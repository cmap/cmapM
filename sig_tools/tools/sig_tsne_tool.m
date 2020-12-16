function sig_tsne_tool(varargin)
% SIG_TSNE_TOOL Run t-SNE on a multi-dimensional data matrix.
% See: sig_tsne_tool -h for details

obj = mortar.sigtools.SigTSNE;
obj.run(varargin{:});

% import mortar.sigtools.SigTsne
% import mortar.util.Message

% [args, help_flag] = SigTsneTool.getArgs(varargin{:});

% if ~help_flag
%     try
%         t0 = tic;
%         wkdir = args.out;
%         res = SigTsneTool.runAnalysis(args);
%         SigTsneTool.saveResult(res, wkdir);
%         tend = toc(t0);
%         mortar.util.Message.log(fullfile(wkdir, 'success.txt'), ...
%                                 'Completed in %2.2fs', tend);
%     catch e
%         mortar.util.Message.log(1, e);
%         if ~isempty(wkdir)
%             err_file = fullfile(wkdir, 'failure.txt');
%             Message.log(err_file, e);
%             Message.log(1, 'Stack trace saved in %s', err_file);
%         end
%     end
% end