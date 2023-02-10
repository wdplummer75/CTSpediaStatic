source("http://www.ctspedia.org/wiki/pub/CTSpedia/StatToolsTopic060/U_ICC.R")
n=200
rou=0.5
#simulate data
y=matrix(0,n,5)
si=2*rou/(1-rou)
b=rep(0,n)
for (i in 1:n) 
{
b[i]=rnorm(1,mean=0,sd=sqrt(si))
for (j in 1:5){
y[i,j]=1+b[i]+rchisq(1,df=1)-1
}
}

gg=cll(n,5,y)
cat("U_ICC example output\n\n")
print(gg)



