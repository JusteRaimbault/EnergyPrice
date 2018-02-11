
setwd(paste0(Sys.getenv('CS_HOME'),'/EnergyPrice/Models/SpatialAnalysis'))

library(dplyr)
library(rgdal)
library(rgeos)
library(ggplot2)

source('functions.R')

countydata = as.tbl(read.csv(paste0(Sys.getenv('CS_HOME'),'/EnergyPrice/Data/processed/processed_20170320/county_daily_data.csv'),sep=";",header=T,stringsAsFactors = F,colClasses = c("character","integer","character","numeric","numeric","numeric","numeric")))
addresses = as.tbl(read.csv(paste0(Sys.getenv('CS_HOME'),'/EnergyPrice/Data/processed/processed_20170320/addresses.csv'),sep=";",header=T,stringsAsFactors = F))
counties <- readOGR(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Data/processed/processed_20170320/gis'),layer = 'county_us_metro',stringsAsFactors = FALSE)
states <- readOGR(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Data/states'),layer = 'us_metro',stringsAsFactors = FALSE)

taxes<-as.tbl(read.csv(paste0(Sys.getenv('CS_HOME'),'/EnergyPrice/Data/states/taxstate.csv'),sep=";",stringsAsFactors=F))

states@data = left_join(states@data,taxes,by=c("STUSPS"="state"))

resdir <- paste0(Sys.getenv('CS_HOME'),'/EnergyPrice/Results/SpatialAnalysis/')

##
# filter some strange observations (<1.5, >4, not countinous in time : seem to be bug)
#countydata=countydata[countydata$meanprice<4&countydata$meanprice>1.5,]

# filter on number of observations
bycountyobs = countydata%>%group_by(countyid)%>%summarise(nobs=sum(nobs))
countiesth = bycountyobs$countyid[bycountyobs$nobs>=30]
countydata=countydata[countydata$countyid%in%countiesth,]
# cdf of prices : jump mean aberrant values
#plot(sort(countydata$meanprice),log(1:nrow(countydata)),type='l')
#plot(sort(countydata$meanprice[countydata$meanprice>3.6]),log(1:length(which(countydata$meanprice>3.6))),type='l')
# low values are nonsense but high does not seem
countydata=countydata[countydata$meanprice>1,]


# TODO : power law in price distribution ? in any case fat tail !
#  have a look at that !


# number of obeservations per fuel
nobstot = sum(countydata$nobs)
countydata%>%group_by(type)%>%summarise(nobs=sum(nobs)/nobstot)

# number of stations
nstations = length(unique(addresses$id))


# maps of prices per county

# group by month

countydata$month = floor(countydata$day/100)
countydata%>%group_by(month)%>%summarise(count=n())

#opar <- par(mar = c(0.75,0.75,1.5,0.75))
#plot(states, border = NA, col = "white", bg = "#A6CAE0")
#plot(world.spdf, col  = "#E3DEBF", border=NA, add=TRUE)

staxes = states$statetax;names(staxes)=states$STATEFP
countystates = counties$STATEFP;names(countystates)<-counties$GEOID
countydata$taxes=staxes[countystates[countydata$countyid]]

sdata = countydata[countydata$type=="Regular",]%>%group_by(countyid)%>%summarise(price=mean(meanprice)/(1+mean(taxes/100)))
#sdata = countydata[countydata$type=="Regular"&countydata$month>201702,]%>%group_by(countyid)%>%summarise(price=mean(meanprice))


filename='average_regular_map_fr'
title = "Prix moyen par comte"
legendtitle="Prix\n($/gal)"

mapCounties(data=data.frame(sdata),"price",filename,title,legendtitle)



filename='average_regular_notaxes_map'
title = "Average price by county, net of taxes"
legendtitle="Price\n($/gal)"

mapCounties(data=data.frame(sdata),"price",filename,title,legendtitle)


###########
###########
# ts plotting

# do some clustering to plot time series ?

date = strptime(as.character(countydata$day),format='%Y%m%d')
g=ggplot(data.frame(countydata[countydata$type=="Regular",],date),aes(x=date,y=meanprice,color=countyid,group=countyid))
g+geom_line(show.legend = F)




############
############

# autocorrelation analysis
source('functions.R')

getDailyPrices<-function(day){
  sdata = data.frame(countydata[countydata$type=="Regular"&countydata$day==day,]%>%group_by(countyid)%>%summarise(price=mean(meanprice)))
  rownames(sdata)<-as.character(sdata$countyid)
  prices = sdata[counties$GEOID,2]
  #prices=prices[!is.na(prices)]
  prices[is.na(prices)]=0
  return(prices)
}

daycounts = countydata[countydata$type=="Regular",]%>%group_by(day)%>%summarise(count=n())
# -> le 6 mars est chie, ?? virer (corresponds to end of hole ?)

n=length(counties)
m = matrix(rep(1,n*n),nrow=n,ncol=n);diag(m)<-0

# search for some kind of transition at the state scale ?
alldecays=c(1,10,100,1000)
alldays=sort(unique(countydata$day[countydata$day!=20170306]))
# plot(1:length(alldays),alldays)

autocorrs = c();days=c();decays=c()
for(decay in alldecays){
  show(decay)
  w=weightMatrix(decay,counties)
  for(day in alldays){
    show(day)
    prices = getDailyPrices(day)
    rho = autocorr(prices,w,m)
    #autocorrs=append(autocorrs,rho)
    #days=append(days,rep(day,length(rho)));decays=append(decays,rep(decay,length(rho)))
    autocorrs=append(autocorrs,mean(rho));days=append(days,day);decays=append(decays,decay)
  }
}

g=ggplot(data.frame(rho=autocorrs,day=strptime(as.character(days),format='%Y%m%d'),decay=as.character(decays)),aes(x=day,y=rho,color=decay,group=decay))
g+geom_point(size=0.5)+stat_smooth(se = T,span = 0.2)+ylab("Moran index") + 
  theme(axis.title = element_text(size = 15), axis.text.x = element_text(size = 10), axis.text.y = element_text(size = 10))
ggsave(file=paste0(resdir,'moran_days.pdf'),width=10,height=5)


## by week, as function of decay

getWeeklyPrices<-function(startDayIndex){
  currentdays = alldays[startDayIndex:min((startDayIndex+6),length(alldays))]
  sdata = data.frame(countydata[countydata$type=="Regular"&countydata$day%in%currentdays,]%>%group_by(countyid)%>%summarise(price=mean(meanprice)))
  rownames(sdata)<-as.character(sdata$countyid)
  prices = sdata[counties$GEOID,2]
  #prices=prices[!is.na(prices)]
  prices[is.na(prices)]=0
  return(prices)
}

alldecays=10^seq(from=0,to=4,by=0.2)

autocorrs = c();days=c();decays=c()
for(decay in alldecays){
  show(decay)
  w=weightMatrix(decay,counties)
  for(day in seq(from=1,to=length(alldays),by=8)){
    show(day)
    prices = getWeeklyPrices(day)
    rho = autocorr(prices,w,m)
    autocorrs=append(autocorrs,mean(rho));days=append(days,day);decays=append(decays,decay)
  }
}

g=ggplot(data.frame(rho=autocorrs,week=strptime(as.character(alldays[days]),format='%Y%m%d'),decay=decays),aes(x=decay,y=rho,color=week,group=week))
g+geom_point()+geom_line()+scale_x_log10()+ylab("Moran index") + 
  theme(axis.title = element_text(size = 22), axis.text.x = element_text(size = 15), axis.text.y = element_text(size = 15))
ggsave(file=paste0(resdir,'moran_decay_weeks.pdf'),width=10,height=5)



# map autocorrelation on all period
prices = getPeriodPrices()
w=weightMatrix(100,counties)
rho = autocorr(prices,w,m);names(rho)<-counties$GEOID
sdata$rho=rho[sdata$countyid]

filename='local_moran_map'
title = "Local Moran index"
legendtitle="Local Moran"

mapCounties(sdata,"rho",filename,title,legendtitle)




