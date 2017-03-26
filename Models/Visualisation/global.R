

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
counties <- readOGR(dsn='data/gis',layer = 'county_us_metro',stringsAsFactors = FALSE)
states <- readOGR(dsn='data/gis',layer = 'us_metro',stringsAsFactors = FALSE)

##

getData <- function(data,daysts,dayfts){
  return(data[data$day>=daysts&data$day<dayfts,])
}

days =sort(unique(countydata$day[countydata$day!=20170306]))
  
globalReactives = reactiveValues()

globalReactives$currentDay = days[1]
currentDailyData = getData(countydata,days[1],days[2])
globalReactives$currentDailyData = currentDailyData
#globalReactives$times = unique(currentDailyData$ts)
#globalReactives$mintps = currentDailyData %>% group_by(id) %>% summarise(mintps=max(1,min(tps)))
globalReactives$dates = as.POSIXct(unique(currentDailyData$day), origin="1970-01-01")






