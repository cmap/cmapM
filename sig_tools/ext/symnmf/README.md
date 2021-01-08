# Symmetric NMF for graph clustering

**Symmetric nonnegative matrix factorization (SymNMF)** is an unsupervised algorithm for graph clustering, and has found numerous use cases with itself or its extensions [(Google Scholar)](https://scholar.google.com/scholar?oi=bibs&hl=en&cites=5171938689932689716), many of which are in bioinformatics and genomic study.

This Matlab package is developed for the following paper:
```
Da Kuang, Chris Ding, Haesun Park,
Symmetric Nonnegative Matrix Factorization for Graph Clustering,
The 12th SIAM International Conference on Data Mining (SDM '12), pp. 106--117, 2012.
```
and a journal version:
```
Da Kuang, Sangwoon Yun, Haesun Park,
SymNMF: Nonnegative low-rank approximation of a similarity matrix for graph clustering,
Journal of Global Optimization, 62(3):545-574, 2015.
```
Please cite this paper if you find the code useful.

## Problem Statement

SymNMF is defined as:
```
    min_H f(H) = ||A - HH'||_F^2 subject to H >= 0
```
where the input A is an N-by-N symmetric matrix containing pairwise similarity values, and the output H is an N-by-K nonnegative matrix indicating clustering assignment. SymNMF uses the same input similarity matrix A as in spectral clustering, but imposes different constraint on H.

All these Matlab functions are documented. To get started, run the script `test.m` Please find the helper texts at the beginning of each M-file for more options.

## Basic usage

To run SymNMF on a similarity matrix:
```
H = symnmf_newton(A, k)
```
or:
```
H = symnmf_anls(A, k)
```
To run SymNMF on a data matrix for graph clustering:
```
idx = symnmf_cluster(X, k)
```
Please refer to the documentation for more options. A summary of the functions in this package is listed below:

User functions (API):
* `symnmf_newton.m`: Newton-like algorithm for SymNMF, accepting a similarity matrix as input
* `symnmf_anls.m`: ANLS algorithm for SymNMF, accepting a similarity matrix as input
* `symnmf_cluster.m`: A wrapper for graph clustering, accepting a data matrix as input

Auxiliary files:
* `scale_dist3.m`: Computes the affinity matrix of a dense graph with Gaussian similarity
* `scale_dist3_knn.m`: Computes the affinity matrix of a sparse graph with Gaussian similarity
* `inner_product_knn.m`: Computes the affinity matrix of a sparse graph with inner product similarity
* `dist2.m`: Computes a matrix of squared Euclidean distance values
* `nnlsm_blockpivot.m`: The block pivoting algorithm for nonnegative least squares (courtesy of Jingu Kim)
* `graph.data`: A simple graph clustering example
* `test.m`: A test script running on the graph.data example

## Which algorithm to choose

If the similarity matrix is dense (i.e. N is not extremely large and an N-by-N dense matrix can be stored into memory), then we recommend `symnmf_newton`.

If the similarity matrix is sparse (especially when an N-by-N dense matrix cannot be stored into memory), then we recommend `symnmf_anls`. (the default option in `symnmf_cluster`)

`symnmf_newton` will generate more accurate solutions, whereas `symnmf_anls` is generally faster and applicable to larger problems. Please find more options for further acceleration in the helper text of `symnmf_anls`.

## NOTE

The documentation (as well as the cited paper) differentiates the term *affinity matrix* and the term *similarity matrix*.

An *affinity matrix* contains the raw edge weights in a graph, whereas a *similarity matrix* is formed based on the affinity matrix and is directly fed into `symnmf_newton`.

For example, `scale_dist3`, `scale_dist3_knn`, `inner_product_knn` routines all compute the affinity matrix; the similarity matrix in normalized cut is a normalized version of the affinity matrix.
