MWW_longitudinalDatasimu <- function(nT,samplesizeK,m,v,rho){
# nT: number of time points
# samplesizeK: a vector of sample sizes for K groups (e.g. [10 6 20])

library(mvtnorm)

rho_vec <- rho^(1:(nT-1))
cumn <- c(0,cumsum(samplesizeK))
K <- length(samplesizeK)

y <- matrix(nrow=sum(samplesizeK),ncol=nT+1)
for (k in 1:K){
  sigma <- v[k]*diag(nT)
  for (t in 1:(nT-1)){
    sigma[t,(t+1):nT] <- rho_vec[1:length((t+1):nT)]
    sigma[(t+1):nT,t] <- rho_vec[1:length((t+1):nT)]
    }
  yk <- rmvnorm(samplesizeK[k], rep(m[k],nT), sigma)
  y[(cumn[k]+1):cumn[k+1],1:nT] <- yk
  y[(cumn[k]+1):cumn[k+1],nT+1] <- k
  }
return(y)
}

