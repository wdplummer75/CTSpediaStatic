###################################################################################################
###################################################################################################
# Function Name: PLS.r                                                     
#                                                                          
# Description: Multivariate Partial Least Squares.                           
#   This function computes the K PLS components based on X &               
#   Y matrices and associated quantities. Y can be a vector or             
#   a matrix of multiple responses.                                        
#                                                                          
# Input argument(s):                                                       
#   X_s  Matrix of predictors (genes)--standardized to mean 0 variance 1   
#        variance 1 ("training X" of size n x p).                          
#   Y_s  Matrix (or vector) of responses Y_s--also standardized           
#        ("training Y" of size nxL).                                       
#   X_ps Matrix of predictor values (test/validation X) to construct       
#        test components, X_ps (of size mxp).                              
#   lv   The number of PLS components (lv).                                
#                                                                          
# Return(s):                                                               
#   T1   n x lv matrix of PLS training components based on training        
#        information.                                                      
#   T2   m x lv matrix of PLS test components contructed from training     
#        information.                                                      
#   PVEX 1 x lv vector of cummulative percent of X-variation explained.    
#   PVEY 1 x lv vector of cummulative percent of Y-variation explained.    
#   W    p x lv matrix of X-weights.                                       
#   B    p x 1 vector of "regression coefficients".                        
#   V    p x 1 vector of linear combination of sum of squares of X-weights 
#        This is the so called 'VIP' (variable influence on projection)    
#        (Wold 1994; SAS Institue Inc., 1999).                             
#                                                                          
# Call(s): This function calls other function(s):                          
#   None.                                                                  
#                                                                          
# History:                                                                 
# Date/Last Modified: 10.28.01/07.19.01 (Danh V. Nguyen), Matlab code.     
# Translated to R in 2007 (Ying Chen).                                     
# Full testing of exact correspondence of results to Matlab, R and SAS     
# 08.14.08 (D.V. Nguyen).                                                  
#                                                                          
#                                                                          
# References:                                                             
#   SAS Institute Inc. (1999). The PLS procedure. SAS/STAT User's Guide,   
#     Version 8, Cary, NC, pp. 2693-2734.                                  
#   Wold, S. (1994). PLS for multivariate linear modeling. In Waterbeemed, 
#     H. (ed), Chemometric Methods in Molecular Design, Verlag-Chemie,     
#     Germany, pp. 195-218.                                                 
#                                                                          
# Note(s): 								                                   
#   X is standardized so rank(X)=n-1 so maximun value that lv can take is  
#   n-1. Also, to get the correct test components the standardization of   
#   the test data X_p (denoted X_ps) needs to be done properly; i.e. based 
#   on column means and variance from the training data. X_ps is obtained  
#   by call to function STANDARDIZE_PRED.m.                                
#                                                                           
# Example:                                                                   
#                                                                          
# library(multtest) #to get Golub et al. (1999) leukemia data              
# data(golub)                                 
# X <- t(golub); dim(X) #[1]   38 3051 
# y <- golub.cl # sample labels: 27 acute lymphoblastic leukemia (ALL=0) 
#               # cases 11 acute myeloid leukemia (AML=1).
# pls.fit <- PLS(X, X, y, 3) # fit PLS with K=3 components.
# 
# Plot fited PLS componets:
# par(mfrow=c(2,2))  
# plot(pls.fit$T1[,1:2], type='n', xlab='PLS component 1', ylab='PLS component 2')
# points(pls.fit$T1[y==0,1:2], pch=1)
# points(pls.fit$T1[y==1,1:2], pch=2)
# legend(30, 25, c('ALL', 'AML'), pch=c(1,2))
#  
# plot(pls.fit$T1[,c(1,3)], type='n', xlab='PLS component 1', ylab='PLS component 3')
# points(pls.fit$T1[y==0,c(1,3)], pch=1)
# points(pls.fit$T1[y==1,c(1,3)], pch=2)
#  
# plot(pls.fit$T1[,c(2,3)], type='n', xlab='PLS component 2', ylab='PLS component 3')
# points(pls.fit$T1[y==0,c(2,3)], pch=1)
# points(pls.fit$T1[y==1,c(3,3)], pch=2)
#
# Note: If there's no test data set X_ps to the trainin data X_s.                           
###################################################################################################
###################################################################################################

PLS <- function(X_s, X_ps, Y_s, lv) {

# Initialize matrices

E <- X_s
F <- Y_s

N <- nrow(X_s)
px <- ncol(X_s)
py <- ncol(Y_s)
Nx <- nrow(X_ps)

Xap <- matrix(0,N,px)
Yap <- matrix(0,N,py)

#--------------------------------------------------------------------------------------------------

u <- t <- matrix(0,N,lv)
p <- w <- Wnorm <- matrix(0,px,lv)
c <- matrix(0,py,lv)
b <- seq(0,0,len=lv)
t2 <- matrix(0,Nx,lv)

XapXap <- X_sX_s <- EE <- seq(0,0,len=px)
YapYap <- Y_sY_s <- FF <- seq(0,0,len=py)

pvexoverload <- pveyoverload <- pveEoverload <- pveFoverload <- seq(0,0,len=lv)

part_rsq <- seq(0,0,len=lv)

#--------------------------------------------------------------------------------------------------

# Basic PLS algorithm

eps <- 1e-12

for (i in 1:lv) {
    u[,i] <- F[,1]
    
    # to start while loop
    t[,i] <- matrix(1,N,1)*100
    t_old <- matrix(0,N,1)
    diff <- t[,i]-t_old
    
    while (t(diff)%*%diff > eps) {
          t_old <- t[,i]
          wp <- t(u[,i])%*%E/as.numeric(t(u[,i])%*%u[,i])
          w[,i] <- t(wp)/sqrt(as.numeric(wp%*%t(wp)))
          t[,i] <- E%*%w[,i]
          cp <- t(t[,i])%*%F/as.numeric(t(t[,i])%*%t[,i])
          c[,i] <- t(cp)/sqrt(cp%*%t(cp))
          u[,i] <- F%*%c[,i]
          diff <- t[,i]-t_old
    }     
    
    p[,i] <- t(E)%*%t[,i]/as.numeric(t(t[,i])%*%t[,i])
    pp <- sqrt(t(p[,i])%*%p[,i])
    p[,i] <- p[,i]/pp
    t[,i] <- t[,i]*pp
    w[,i] <- w[,i]*pp
    b[i] <- t(u[,i])%*%t[,i]/(t(t[,i])%*%t[,i])

    E <- E-t[,i]%*%t(p[,i])
    F <- F-b[i]*t[,i]%*%t(c[,i])

    # check calculation of PVE's & PLS decomposition
    
    Xap <- Xap+t[,i]%*%t(p[,i])
    Yap <- Yap+b[i]*t[,i]%*%t(c[,i])

    # Overload method

    for (j in 1:px) {
        XapXap[j] <- sum(Xap[,j]^2)
        X_sX_s[j] <- sum(X_s[,j]^2)
        EE[j] <- sum(E[,j]^2)
    }
    
    for (j in 1:py) {
        YapYap[j] <- sum(Yap[,j]^2)
        Y_sY_s[j] <- sum(Y_s[,j]^2)
        FF[j] <- sum(F[,j]^2)
    } 
    
    pvexoverload[i] <- sum(XapXap)/sum(X_sX_s)
    pveyoverload[i] <- sum(YapYap)/sum(Y_sY_s)
    pveEoverload[i] <- sum(EE)/sum(X_sX_s)
    pveFoverload[i] <- sum(FF)/sum(Y_sY_s)
 
}

# calculation of X & Y percent variation explanied

PVEX <- 1-pveEoverload
PVEY <- 1-pveFoverload

# calculation of test components based on training information

X_ps0 <- X_ps

t2[,1] <- X_ps0%*%w[,1]
for (i in 1:lv-1) {
    Xtemp <- X_ps0-t2[,i]%*%t(p[,i])
    t2[,i+1] <- Xtemp%*%w[,i+1]
    X_ps0 <- Xtemp
}

# PLS components and weights
T1 <- t
T2 <- t2
W <- w

# compute "regression coefficients"

P <- p
Q <- c
B <- W%*%solve(t(P)%*%W)%*%diag(b,nrow=lv,ncol=lv)%*%t(Q)

# compute VIP

num_var <- ncol(X_s)

for (i in 1:lv) {
     Wnorm[,i] <- W[,i]/sqrt(t(W[,i])%*%W[,i])
}

# Wnorm <- unlist(apply(W,2,function(x) x/sqrt(t(x)%*%x)))

rsq_y <- t(PVEY)

for (i in 1:lv) {
    if (i==1) {
        part_rsq[i] <- rsq_y[1]
    } else {
        part_rsq[i] <- rsq_y[i]-rsq_y[i-1]
    }
}

total_rsq <- rsq_y[lv]

V_sq <- ((Wnorm^2)%*%part_rsq)*(num_var/total_rsq)

V <- sqrt(V_sq)

return(list(W=W,PVEX=PVEX,PVEY=PVEY,T1=T1,T2=T2,B=B,V=V))

}






