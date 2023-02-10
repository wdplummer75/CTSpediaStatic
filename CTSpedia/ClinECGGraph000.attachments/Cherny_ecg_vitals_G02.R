# clear objects
rm(list = ls())     

# close graphics windows
graphics.off()      

#Need gridExtra for gridtext function
require(gridExtra)

#Read data. Make sure to specify path to the data file
ecg <- read.table("tqt.dat", 
                  header=FALSE, sep=",", na.strings="NA", dec=".", strip.white=TRUE)


#create x, y, group and page variables
ecg$tpd<-ecg$V3
ecg$y<-ecg$V20
ecg$x<-ecg$V8

#create numeric code variables for group
ecg$groupcd<-as.numeric(ecg$V22)
#create labels for groups
ecg$group<- factor(ecg$groupcd, labels = c("Exp Low Dose", "Exp High Dose",  "Placebo", "Moxifloxacin") )
#create short labels for groups
ecg$groupt<- factor(ecg$groupcd, labels = c("l", "h", "p", "m") )
#keep only the required variables in dataset
ecg<-ecg[c("x", "y", "groupcd", "tpd", "group", "groupt" )]

#remove any records with missing data
ecg<-na.omit(ecg)  

#check the ranges for x and y
range(ecg$x,na.rm=TRUE)
range(ecg$y,na.rm=TRUE)

#create dataset containing unique TPD records
unique_ecgs<-subset(ecg, !duplicated(tpd))

#create variable representing row number for tpd variable. The counter will be used to create a graph per single page
for (i in 1:nrow(unique_ecgs)) {
  unique_ecgs$tpdcd[i]=i
}
unique_ecgs<-unique_ecgs[,c('tpd', 'tpdcd')]
#add tpd counter to ECG dataset
ecg<-merge(ecg, unique_ecgs, by=c("tpd"), sort=T, all.y=T)

#determine number of pages
number_of_pages<- as.numeric(max(unique(ecg$tpdcd)))

#determine number of treatments
number_of_trt<- max(ecg$groupcd,na.rm=TRUE)

# PDF file name. Add file path here
somePDFPath = "ecg_vitals_G02.pdf"

#direct output to PDF
pdf(file=somePDFPath,  paper='A4r', width=15, height=8)

#set up margins
par(new=T, par(mar=c(12,5,11,1)))

#set up colors for each treatment
colors<-c("cyan", "blue","red","black")

#set up symbols for each treatment
plotchar <-c(76,72,80,77) #77-M 76-L 72-H 80-P

#plotchar <-c(108,104,112,109) #109 produces m as symbol, 108-l, 104 -h, 112-p. This code may be used for lower case letter symbols

#Start a loop to create a graph per page
for (ii in 1:number_of_pages) 
{
  
    #create a temporary dataset for per (i.e. the timepoint)
    ecg_temp1 <- subset(ecg,  tpdcd==ii )
  
    #create empty plot. The points will be added later
    plot( ecg_temp1$y~ecg_temp1$x, 
          ylim = c(-60, 70) , #y-axis scale
          type="n", #supress plot
          yaxt = "n", 
          xaxt="n", 
          xlab="Baseline QTc (milliseconds) - Fridericia Correction",        
          ylab=" QTc Change (milliseconds) - Fridericia Correction",
          xlim = c(350, 460)  #x-axis scale
          )
    
    #plot points for each treatment
    for (i in 1:number_of_trt) 
    {
      #create temporary dataset for the treatment
      ecg_temp2 <- subset(ecg_temp1,  groupcd==i ) #subset temp dataset
      
      #plot points
      points(ecg_temp2$x, 
             ecg_temp2$y,
             cex=0.6, #size of points
             col=colors[i], #color of points
             pch=plotchar[i]  #symbol of points
             )        
  } #end of (i in 1:number_of_trt) loop
  
  
  #legend
  legend("bottom"  ,   
         inset=-0.5, #inset will display the legend below the plot
         xpd=T, 
         as.character(unique(ecg$group)), #text for legend
         cex=1, 
         col=colors,
         pch=plotchar, 
         ncol=4,
         title="Treatments:")
  
    #this function is needed to determine the angle of reference line labes
    getCurrentAspect <- function() { 
      uy <- diff(grconvertY(1:2,"user","inches")) 
      ux <- diff(grconvertX(1:2,"user","inches")) 
      uy/ux 
    } 
    asp <- getCurrentAspect();
    
  #add reference lines
  abline (h=0, lty=2)
  abline (h=30, lty=2)
  abline (h=60, lty=2)
    
  #diagonal reference lines  
  abline(a=450, b=-1, lty = 2)
  text(x=400, y=55, "450 msec", srt=180/pi*atan(-1*asp))
    
  abline(a=480, b=-1, lty = 2)
  text(x=430, y=55, "480 msec", srt=180/pi*atan(-1*asp))
    
  abline(a=500, b=-1, lty = 2)
  text(x=450, y=55, "500 msec", srt=180/pi*atan(-1*asp))
    
  
  #display x axis
  xaxis_marks <- seq(340,480,by=10)
  axis(1, tick=T, at=xaxis_marks,labels = T)
  
  #display y axis
  yaxis_marks <- seq(-70,80,by=10)
  axis(2, tick=T, at=yaxis_marks, las=2 ) #use las to display horizontal label on Y axis
  
  #add text at fixed positions
  grid.text(paste("user_id: ",toupper(format(Sys.time(), "%d%B%Y %H:%M"))), x=0.01, y=0.06,just="left")
  grid.text("Protocol: text", x=0.01, y=0.93,just="left")
  grid.text("Population: Text", x=0.01, y=0.9,just="left")
  grid.text( paste("Page", ii,  "of", number_of_pages), x=0.9, y=0.9,just="left")
  grid.text(paste("ECG/VITALS G2"), x=0.5, y=0.88)
  grid.text("Figure Number", x=0.5, y=0.85)
  grid.text("Title2 (Base R)", x=0.5, y=0.82)
  grid.text( paste("Hour:", unique(ecg_temp2$tpd)),, x=0.5, y=0.75)
} #end of (ii in 1:number_of_pages) loop


dev.off()