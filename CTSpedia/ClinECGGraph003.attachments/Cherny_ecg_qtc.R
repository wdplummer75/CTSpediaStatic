# clear objects
rm(list = ls())     

# GGPLOT
library(ggplot2)

# close graphics windows
graphics.off()      

#set hours values
hours<- c(6, -4, -2, 0, 2, 4,6,8,10)
  
# Create ECG dataset with some random QTC values
# set subject id to be within 20-39 range
ecg= data.frame(
  subjid=  rep(20:39, each = 9),
  hours = rep(c(hours),20),
  qtc=sample(330:520, 180, replace=F))

# Create DEMO dataset with some random gender values
demo= data.frame(
  subjid=  rep(20:39),
  gender=sample(1:2, 20, replace=T))

# Add gender values to ECG dataset 
ecg<-merge(ecg, demo, by=c("subjid")) 

# concatanate gender and subject ID together into a new variable
ecg$gender_text<-ifelse (ecg$gender==1, "Male", "Female")
ecg$subjid_gender<-  paste(ecg$subjid,"    ", ecg$gender_text)

# plot data
ggplot(data=ecg, 
       aes(x=hours, 
           y=qtc)) + 
  geom_line() +
  ylab("QTc (ms)")+
  geom_point()+
  facet_wrap( ~subjid_gender)+
  geom_hline(yintercept = 420, colour="red")+  
  scale_x_continuous("Time relative to First Dose (Hr)", 
                     breaks = c(hours))
