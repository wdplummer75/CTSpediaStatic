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

UGEE2 <- function(y1,y2){
f <- numeric(length(y1))
for (i in 1:length(y1)){
  f[i] <- sum(y1[i]<=y2)/length(y2)
  }
theta=sum(f)/length(y1)
return(theta)
}

