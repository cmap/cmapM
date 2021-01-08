function GuidedPCA(x, batch, nfilt, nperm, is_centered, do_scaley, rnd_seed)
% gPCA.batchdetect <-
% function(x,batch,filt=NULL,nperm=1000,center=FALSE,scaleY=FALSE,seed=NULL){
% 	
% 	# x : n x p matrix of genomic data
% 	# batch : length n vector indicating batch for each sample
% 	# filt : number of features to retain after filtering
% 	# nperm : number of permutations to perform during the permutation test
% 	# x2.imp : optional centered data matrix with imputed missing values 
%  	# center : logical, is the data centered?
%  	# scaleY : should Y be scaled based on number of samples in each batch?
%  	# seed : ability to set the seed for random sampling

narginchk(2, 7);
nin = nargin;

[nx, px] = size(x);
batch = batch(:);
nb = length(batch);

assert(isequal(nx, nb),...
    'Expected batch vector to equal %d rows of X, got %d', nx, nb)

% if(!is.null(seed)){set.seed(seed)}
if ~isempty(rnd_seed)
    rng(rnd_seed)
end

% # Permute batch:	
% permute<-matrix(NA,ncol=length(batch),nrow=50000)
% for (j in 1:50000) {permute[j,]<-sample(batch,replace=FALSE)}
% samp<-sample(1:dim(permute)[1],nperm,replace=FALSE)
% permute.samp<-permute[samp,]
% 	

% # Center data:
% if(center==FALSE) {
% 	x2<-scale(x,center=T,scale=F)
% 	} else {
% 		x2<-x
% 	}
if is_centered
    x2 = scale_matrix(x, true, false);
else
    x2 = x;
end

% # Test for missing values, impute if missing:
% # (save imputed x2 in working directory so don't have to run it again)	
% if(sum(is.na(x))>0) { 
% 		missing<-readline(prompt="Missing values detected. Continue with mean value imputation? (Note this may take a very long time, but it will automatically save in your working dir so you don't have to ever run it again.) [y/n] ")
% 		if (substr(missing,1,1)=="n") {
% 			stop("The PC cannot be calculated with missing values.")
% 		} else {
% 			x2.imp<-ifelse(is.na(x2),rowMeans(x2,na.rm=TRUE),x2)
% 			save(x2.imp,"x2.imputed.RData")
% 		}		
% } else {
% 	x2.imp<-x2
% }
inan = isnan(x);
if any(inan)
    dbg(1, 'Imputing missing values using row means');
    [ir, ic] = find(inan);
    row_means = nanmean(x2, 2);
    x2_imp(inan) = row_means(ir);
else
    x2_imp = x2;    
end

% 
% # Filter data:
% if(is.null(filt)){ 
% 	data.imp<-x2.imp
% 	} else {
% 		sd<-apply(x2.imp,2,sd)
% 		rank<-rank(sd)
% 		keep<-(1:length(sd))[rank %in% (length(rank)-filt+1):length(rank)]
% 		data.imp<-x2.imp[,keep]
% 	}
if nfilt>0
    sd = nanstd(x2_imp, 0, 1);
    [~, srt_idx] = sort(sd, 'descend');
    keep = srt_idx(1:min(nfilt, size(x2_imp, 2)));
    data_imp = x2_imp(:, keep);
else
    data_imp = x2_imp;
end

% n<-dim(data.imp)[1]
% p<-dim(data.imp)[2]
% b<-length(unique(batch))
% n ; p ; b
[n, p] = size(data_imp);
b = length(unique(batch));

% ## Test for dimensionality:
% if(length(batch)!=n) {stop("Matrices do not conform: length(batch)!=n")}
% 
% # Establish Y matrix indicating batch:
% y<-matrix(nrow=length(batch),ncol=length(unique(batch)))
% for ( j in 1:length(unique(batch)) ){
% 	y[,j]<-ifelse(batch==j,1,0)
% }
% if (scaleY==FALSE){
% 	y2<-scale(y,center=T,scale=F) #y2.bat
% } else {
% 	ys<-matrix(nrow=length(batch),ncol=length(unique(batch)))
% 	nk<-apply(y,2,sum)
% 	for ( j in 1:length(unique(batch)) ){
% 		ys[,j]<-ifelse(batch==j,1/nk[j],0)
% 	}
% 	y2<-scale(ys,center=F,scale=F) #y2.bat
% }

y = genBatchMatrix(batch);
if do_scaley
    y2 = scale_matrix(y, true, false);
else
    nk = sum(y, 1);
    y2 = bsxfun(@rdivide, y, nk);
end
% 
% # Unguided SVD:
% svd.x<-svd(data.imp)
% 
[u,d,v] = svd(data_imp);

% ### Variance of unguided PCs
% PC.u<-data.imp%*%svd.x$v
% var.x<-var(PC.u)
% varPCu1<-diag(var.x)[1]/sum(diag(var.x))
% cumulative.var.u<-numeric()
% for( i in 1:dim(var.x)[1] ){
% cumulative.var.u[i]<-sum(diag(var.x)[1:i])/sum(diag(var.x))
% }
% 
% Principal component, X*V = U*D
pc_u = u*d;
var_x = d.^2/(n-1);
varPCu1 = var_x(1)/sum(var_x);
cumulative_var_u = cumsum(var_x/sum(var_x));

% # Guided SVD:
% svd.bat<-svd(t(y2)%*%data.imp)
% 
[ug, dg, vg] = svd(y2'*data_imp);

% ### Variance of guided PCs
% PC.g<-data.imp%*% svd.bat$v
% var.bat<-var(PC.g)
% varPCg1<-diag(var.bat)[1]/sum(diag(var.bat))
% cumulative.var.g<-numeric()
% for( i in 1:dim(var.bat)[1] ){
% cumulative.var.g[i]<-sum(diag(var.bat)[1:i])/sum(diag(var.bat))
% }
% 
pc_g = ug*dg;
var_bat = dg^2/(n-1);
varPCg1 = var_bat(1)/sum(var_bat);
cumulative_var_g = cumsum(var_bat/sum(var_bat));

% # Calculate test statistic delta:
% delta<-diag(var.bat)[1]/diag(var.x)[1]
% 
delta = var_bat(1) / var_x(1);

% 
% ##########################################################
% ### Begin loop for random sample of batch permutations ###
% delta.p<-numeric()
% for ( i in 1:nperm ){
% 	
% batch.p<-permute.samp[i,]
% 
% y<-ys<-matrix(nrow=length(batch.p),ncol=length(unique(batch.p)))
% for ( j in 1:length(unique(batch.p)) ){
% 	y[,j]<-ifelse(batch.p==j,1,0)
% }
% if (scaleY==FALSE){
% 	y2<-scale(y,center=T,scale=F) #y2.bat
% } else {
% 	nk<-apply(y,2,sum)
% 	for ( j in 1:length(unique(batch.p)) ){
% 		ys[,j]<-ifelse(batch.p==j,1/nk[j],0)
% 	}
% 	y2<-scale(ys,center=F,scale=F) #y2.bat
% }
% 
% 
% 
% # Perform gPCA
% svd.bat.p<-svd(t(y2)%*%data.imp)
% 
% var.bat.p<-var(data.imp%*% svd.bat.p$v)
% PC.g.p<-diag(var.bat.p)[1]/sum(diag(var.bat.p))
% 
% delta.p[i]<- diag(var.bat.p)[1]/diag(var.x)[1]  #Alternative test statistic
% 
% 
% } # end of permutation loop
% 
% p.val<-sum(delta<delta.p)/length(delta.p)
% p.val
% p.val<-ifelse(p.val==0,"<0.001",round(p.val,3))
% 
% out<-list(delta=delta,p.val=p.val,delta.p=delta.p,batch=batch,filt=filt,n=n,p=p,b=b,
% 	PCg=PC.g,PCu=PC.u,varPCu1=varPCu1,varPCg1=varPCg1,nperm=nperm,
% 	cumulative.var.u=cumulative.var.u,
% 	cumulative.var.g=cumulative.var.g)
% 
% }

end

function bm = genBatchMatrix(batch)
[cn, nl] = getcls(batch);
nb = length(cn);
bm = bsxfun(@eq, nl, 1:nb);
end


