

cll=function(n,t,y){


tth1=0
tth2=0
for ( i in 1:(n-1))
{
for (j in ((i+1):n))
{
for (k in 1:(t-1))
{
for (m in ((k+1):t))
{
tth1=tth1+0.5*(y[i,k]-y[j,k])*(y[i,m]-y[j,m])
}
}

for(k in 1:t){
tth2=tth2+0.5*(y[i,k]-y[j,k])^2
}

}
}

tth1=tth1/choose(t,2)/choose(n,2)
tth2=tth2/t/choose(n,2)

tth=c(tth1,tth2)



u1=rep(0,n)
u2=rep(0,n)
for(i in 1:n)
{
for (k in 1:(t-1))
{
for (m in ((k+1):t))
{

u1[i]=u1[i]+(y[i,k]-1)*(y[i,m]-1)

}
}
u1[i]=u1[i]/choose(t,2)
}

for(i in 1:n){

for (k in 1:t){

u2[i]=u2[i]+(y[i,k]-1)^2

}

u2[i]=u2[i]/t
}

sigh=0

for(i in 1:n){

sigh=sigh+ (c(u1[i],u2[i])-tth)%*%t(c(u1[i],u2[i])-tth)

}

sigh=sigh/(n-1)

gg=matrix(c(1/tth2,-tth1/(tth2^2)),1,2)

xsigh=(gg)%*%sigh%*%t(gg)

rouh=tth1/tth2


result=matrix(0,1,2)
colnames(result) <- c("estimate","s.e.")
rownames(result) <- c("ICC")
result[,1]=rouh
result[,2]=sqrt(diag(xsigh)/n)
return(result)
}









