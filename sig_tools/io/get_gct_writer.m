function gctwriter = get_gct_writer(use_gctx)
% GET_GCT_WRITER Return function handle to gct writer.
% GWH = GET_GCT_WRITER(USE_GCTX) returns handle to MKGCTX if USE_GCTX is
% true or to MKGCT if false.

if use_gctx
    gctwriter = @mkgctx;
else
    gctwriter = @mkgct;
end

end
