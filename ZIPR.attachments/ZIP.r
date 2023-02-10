
zip=function(n,noc,X,Y){

library(numDeriv)
library(nleqslv)

logit<-function(p) return(log(p/(1-p)))
inv.logit<-function(t) return(exp(t)/(1+exp(t)))
dev.logit<-function(t) return(exp(t)/(1+exp(t))^2)



### fitting the zip model 

hit=function(d)
{
hit=inv.logit(d[noc+1])+exp(-exp(d[noc+2]+sum(d[1:noc]*d[(noc+3):(2*noc+2)])))/(1+exp(d[noc+1]))
return(hit)
}


git=function(d)
{
git=exp(d[noc+2]+sum(d[1:noc]*d[(noc+3):(2*noc+2)]))/(1+exp(d[noc+1]))
return(git)
}

Hi=function(d)
{
Hi=matrix(c(hit(d),hit(d),git(d),git(d)
) ,4,1)
return(Hi)
}

Ji=function(Yi)
{
R1=0
if(Yi[1]==0){
R1=1}
R2=0
if(Yi[2]==0){R2=1}
Ji=matrix(c(R1,R2,(1-R1)*Yi[1],(1-R2)*Yi[2]), 4,1)
return(Ji)
}

Di=function(d)
{
Di=t(jacobian(Hi,d)[,(noc+1):(2*noc+2)])
return(Di)
}

Di1=function(d)
{
Di=jacobian(Hi,d)
return(Di)
}



Vi=function(d)
{
Vi=matrix(0,4,4)
v=hit(d)-hit(d)^2
w=exp(d[noc+2]+sum(d[1:noc]*d[(noc+3):(2*noc+2)]))*(1+exp(d[noc+2]+sum(d[1:noc]*d[(noc+3):(2*noc+2)])))/(1+exp(d[noc+1]))
diag(Vi)=c(v,v,w,w)
return(Vi)
}

### specify the starting value of Newton Rapson method. 
thetanew=matrix(0.8,(noc+2),1)

thetaold=matrix(0,(noc+2),1)


iter=0
while(abs(thetanew-thetaold)>rep(.0001,(noc+2))&&(iter<10))
{
thetaold=thetanew
W1=matrix(0,(noc+2),(noc+2))
W2=matrix(0,(noc+2),1)

for(i in 1:n){
d=c(X[i,],thetaold)
Si=Ji(Y[i,])-Hi(d)
W1=W1+Di(d)%*%solve(Vi(d))%*%t(Di(d))
W2=W2+Di(d)%*%solve(Vi(d))%*%Si
}

thetanew=thetaold+solve(W1)%*%W2
iter=iter+1
}

B.hat=matrix(0,(noc+2),(noc+2))
sandwich=matrix(0,(noc+2),(noc+2))
for (i in 1:n){
d=c(X[i,],thetanew)
D=Di(d)
Si=Ji(Y[i,])-Hi(d)
solve.Vi<-solve(Vi(d))
B.hat<-B.hat+D%*%solve.Vi%*%t(D)/n
sandwich<-sandwich+D%*%solve.Vi%*%Si%*%t(Si)%*%solve.Vi%*%t(D)/n
}
sigma.theta<-solve(B.hat)%*%(sandwich)%*%t(solve(B.hat))
result=matrix(0,(noc+2),2)
colnames(result) <- c("estimate","s.e.")
rownames(result) <- c("beta","intercept",rep("X",noc))
result[,1]=thetanew
result[,2]=sqrt(diag(sigma.theta)/n)
return(result)}
