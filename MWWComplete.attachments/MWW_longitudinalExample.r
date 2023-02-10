source('http://ctspedia.org/wiki/pub/CTSpedia/MWWComplete/MWW_longitudinalDatasimu.r')
source('http://ctspedia.org/wiki/pub/CTSpedia/MWWComplete/MWW_longitudinal.r')

nT<-3
samplesize<-c(20,30)
m<-c(2,3)
v<-c(1,2)
rho <- 0.5
d<-MWW_longitudinalDatasimu(nT,samplesize,m,v,rho)

MWW_longitudinal(d)

