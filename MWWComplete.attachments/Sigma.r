Sigma <- function(data,samplesize,theta,k){
res <- 0
for (i in 1:samplesize[k]){
  A <- meanU(data,samplesize,k,i)
  res <- res+t(A)%*%A-t(theta)%*%theta
  }
return(res)
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