

# setwd(paste0(Sys.getenv('CS_HOME'),'/EnergyPrice/Models/Visualisation'))

# global

library(shiny)
library(leaflet)
library(RColorBrewer)
library(dplyr)
library(rgdal)
library(rgeos)


# gis data
countydata = as.tbl(read.csv(file='data/county_daily_data.csv',sep=";",header=T,stringsAsFactors = F,colClasses = c("character","integer","character","numeric","numeric","numeric","numeric")))
counties <- readOGR(dsn='data/gis',layer = 'county_us_metro_wgs84_simpl',stringsAsFactors = FALSE)
states <- readOGR(dsn='data/gis',layer = 'us_metro_wgs84_simpl',stringsAsFactors = FALSE)

countydata$state = substr(countydata$countyid,1,2)
statedata = countydata %>% group_by(state,day,type) %>% summarise(meanprice=mean(meanprice))

changeLevelFactor = 0.55

##

getData <- function(data,daysts,dayfts){
  return(data[data$day>=daysts&data$day<dayfts,])
}

days =sort(unique(countydata$day[countydata$day!=20170306]))
types = c("Regular","Midgrade","Premium","Diesel")

weeks=c("20170110-20170116","20170117-20170123","20170124-20170201","20170202-20170208",
        "20170209-20170215","20170216-20170222","20170223-20170228","20170307-20170313",
        "20170314-20170319"
        )

globalReactives = reactiveValues()

globalReactives$currentDay = days[1]
currentDailyData = getData(countydata,days[1],days[2])
globalReactives$currentDailyData = currentDailyData
#globalReactives$times = unique(currentDailyData$ts)
#globalReactives$mintps = currentDailyData %>% group_by(id) %>% summarise(mintps=max(1,min(tps)))
globalReactives$dates = as.POSIXct(unique(currentDailyData$day), origin="1970-01-01")






