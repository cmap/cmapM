function qnorm_ds = quantileNormalizeByCell(ds)
% quantileNormalizeByCell Quantile normalize dataset by cell line
% Q = quantileNormalizeByCell(D) Apply quantile normalization to cell
% lines(rows) of the input dataset D. Returns quantile normalized values as
% a dataset Q with the same dimensions as D.

    qnorm_ds = ds;
    qnorm_ds.mat = qnorm(ds.mat')';
end