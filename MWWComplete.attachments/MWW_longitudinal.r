MWW_longitudinal<-function(data){

samplesize <- c(sum(data[,ncol(data)]==1),sum(data[,ncol(data)]==2))
nT <- ncol(data)-1
response<-data[,1:nT]

source('http://ctspedia.org/wiki/pub/CTSpedia/MWWComplete/UGEE_T.r')
source('http://ctspedia.org/wiki/pub/CTSpedia/MWWComplete/Sigma.r')

N_total <- sum(samplesize)
K <- length(samplesize)

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
