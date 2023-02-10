MWW_longitudinal<-function(data){

samplesize <- c(sum(data[,ncol(data)]==1),sum(data[,ncol(data)]==2))
nT <- ncol(data)-1
response<-data[,1:nT]

N_total <- sum(samplesize)
K <- length(samplesize)

UGEE2 <- function(y1,y2){
f <- numeric(length(y1))
for (i in 1:length(y1)){
  f[i] <- sum(y1[i]<=y2)/length(y2)
  }
theta=sum(f)/length(y1)
return(theta)
}


UGEE <- function(data_t,samplesize){
K <- length(samplesize)
ma <- matrix(1, nrow=K, ncol=K)
ma[upper.tri(ma)] <- 0
ind <- which(ma==0,arr.ind=TRUE)
ind <- ind[order(ind[,1]),]+matrix(0,K*(K-1)/2,2)
theta <- numeric(K*(K-1)/2)
for (k in 1:(K*(K-1)/2)){
  sample1 <- ind[k,1]
  start1 <- sum(samplesize[1:sample1-1])+1
  end1 <- start1+samplesize[sample1]-1
  sample2 <- ind[k,2]
  start2 <- sum(samplesize[1:sample2-1])+1
  end2 <- start2+samplesize[sample2]-1
  theta[k] <- UGEE2(data_t[start1:end1],data_t[start2:end2])
  }
return(t(theta))
}

UGEE_T <- function(data,samplesize){
T <- ncol(data)
K <- length(samplesize)
theta <- matrix(nrow=K*(K-1)/2,ncol=T)
for (t in 1:T){
  theta[,t]<-UGEE(data[,t],samplesize)
  }
theta <- c(theta)
return(t(theta))
}


meanU <- function(data,samplesize,k,i){
N <- samplesize
N[k] <- 1
if (k==1) {
data_k <- data[c(sum(samplesize[1:k-1])+i,(sum(samplesize[1:k])+1):sum(samplesize)),]
}
else if (k==length(samplesize)) {
data_k <- data[c(1:sum(samplesize[1:k-1]),sum(samplesize[1:k-1])+i),]
}
else {
data_k <- data[c(1:sum(samplesize[1:k-1]),sum(samplesize[1:k-1])+i,(sum(samplesize[1:k])+1):sum(samplesize)),]
}
res <- UGEE_T(data_k,N)
return(res)
}

Sigma <- function(data,samplesize,theta,k){
res <- 0
for (i in 1:samplesize[k]){
  A <- meanU(data,samplesize,k,i)
  res <- res+t(A)%*%A-t(theta)%*%theta
  }
return(res)
}



theta <- UGEE_T(response,samplesize)

sigma <- 0
for (k in 1:K){
  sigma <- sigma+Sigma(response,samplesize,theta,k)/(samplesize[k]-1)*N_total/samplesize[k]
}

Z <- N_total*(theta-1/2)%*%solve(sigma)%*%t(theta-1/2)
p_chi <- 1-pchisq(Z, df=K*(K-1)*nT/2, ncp=0, log = FALSE)
F <- (N_total-nT)*N_total*(theta-1/2)%*%solve(sigma)%*%t(theta-1/2)/nT/(N_total-1)
p_f <- 1-pf(F, nT, N_total-nT, log = FALSE)

return(list(estimates=theta,pvalue.chisq=p_chi,pvalue.f=p_f))
}
