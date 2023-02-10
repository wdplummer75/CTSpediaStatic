# brew_api_driver.R
library(brew)
setwd("C:/Users/Bob/Desktop/REDCap_Day_2011")
brew('Report_via_API.html', output='report.html')
