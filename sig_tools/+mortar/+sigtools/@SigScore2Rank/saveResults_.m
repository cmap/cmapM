function saveResults_(obj, out_path)
% required_fields = {'args'};
% res = obj.getResults;                
% ismem = isfield(res, required_fields);
% if ~all(ismem)
%     disp(required_fields(~ismem));
%     error('Some required fields not specified');
% end
% 
% if res.args.use_gctx 
%     gctwriter = @mkgctx;
% else
%     gctwriter = @mkgct;
% end
% 
% if isempty(res.args.outfile)
%     gctwriter(fullfile(out_path, 'rank'), res.output);
% else
%     gctwriter(fullfile(out_path, res.args.outfile), res.output);
% end
end