### specify the sample size n and number of covariates noc
n=200
noc=4

### generate the data for model fitting. 
### if you have your own data , for example, 2 covariates, 2 time points, 5 obersavations  
### then Y the outcome is in the form
### 1 1
### 1 1
### 1 1
### 1 1
### 1 1 
### X the covarates is in the form
### 1 1 1
### 1 1 1
### 1 1 1
### 1 1 1
### 1 1 1

beta=1
inter=1
Y=matrix(0,ncol=2,nrow=n)
X=matrix(0,ncol=noc,nrow=n)
rou=inv.logit(beta)
for(i in(1:n)){

X[i,]=rnorm(noc,1,1)
miui=exp(inter+sum(X[i,]))

if(rbinom(1, 1, rou)==0)
{
Y[i,1]=rpois(1, miui)
Y[i,2]=rpois(1, miui)
}
}

zip(n,noc,X,Y)
