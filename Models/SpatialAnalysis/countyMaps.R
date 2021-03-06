
setwd(paste0(Sys.getenv('CS_HOME'),'/EnergyPrice/Models/SpatialAnalysis'))

library(dplyr)
library(rgdal)
library(rgeos)
library(raster)
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

#sdata = countydata[countydata$type=="Regular"&countydata$month>201702,]%>%group_by(countyid)%>%summarise(price=mean(meanprice))
sdata = countydata[countydata$type=="Regular",]%>%group_by(countyid)%>%summarise(price=mean(meanprice,na.rm = T))
#sdata = countydata[countydata$type=="Regular",]%>%group_by(countyid)%>%summarise(price=mean(meanprice)) # same

filename='maps/average_regular_map_fr'
title = "Prix moyen par comte"
legendtitle="Prix\n($/gal)"
mapCounties(data=data.frame(sdata),"price",filename,title,legendtitle)
#mapCounties(data=data.frame(sdata),"price",filename,title,legendtitle,pdf=F)

filename='maps/average_regular_map'
title = "Average price by county"
legendtitle="Price\n($/gal)"
mapCounties(data=data.frame(sdata),"price",filename,title,legendtitle)


sdata = countydata[countydata$type=="Regular",]%>%group_by(countyid)%>%summarise(price=mean(meanprice,na.rm=T)/(1+mean(taxes/100)))

filename='maps/average_regular_notaxes_map'
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



###########
###########

# state time series
statedata <- read.csv(file='../DataCollection/test/states/USStates.csv',stringsAsFactors = F)
#statedata$date <- strptime(gsub("/","",as.character(statedata$date),fixed=T),format='%m/%d/%Y',tz = "GMT")
statedata$date <-as.POSIXct(as.character(statedata$date),format='%m/%d/%Y')
g=ggplot(statedata,aes(x=date,y=price,group=stateid,color=stateid))
g+geom_line()
ggsave(file=paste0(resdir,'states_ts.png'),width=15,height=10,units='cm')



############
############

# correlation number of stations <-> population

cities <- readOGR(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Data/cities/'),layer = 'zip_us_metro',stringsAsFactors = FALSE)
popraster <- raster(paste0(Sys.getenv('CS_HOME'),'/Data/JRC_EC/GHS/GHS_POP_GPW42015_GLOBE_R2015A_54009_1k_v1_0/GHS_POP_GPW42015_GLOBE_R2015A_54009_1k_v1_0.tif'))
citiestr<-spTransform(cities,proj4string(popraster)) #longlat, no need to transform
vals <- getValuesBlock(popraster,row=rowFromY(popraster,bbox(citiestr)[2,2]),
               nrows=rowFromY(popraster,bbox(citiestr)[2,1])-rowFromY(popraster,bbox(citiestr)[2,2])+1,
               col=colFromX(popraster,bbox(citiestr)[1,1]),
               ncols=colFromX(popraster,bbox(citiestr)[1,2])-colFromX(popraster,bbox(citiestr)[1,1])+1
               )
rowrange=rowFromY(popraster,bbox(citiestr)[2,2]):rowFromY(popraster,bbox(citiestr)[2,1])
colrange=colFromX(popraster,bbox(citiestr)[1,1]):colFromX(popraster,bbox(citiestr)[1,2])
cells = cellFromRowCol(popraster,c(matrix(rep(rowrange,length(colrange)),nrow=length(colrange),byrow=T)),rep(colrange,length(rowrange)))
xcoords = xFromCell(popraster,cells);ycoords = yFromCell(popraster,cells)
poppoints = SpatialPointsDataFrame(matrix(c(xcoords,ycoords),nrow=length(xcoords),byrow = F),data = data.frame(pop=vals,x=xcoords,y=ycoords),proj4string = CRS(proj4string(citiestr)))
# reproject
poppoints = spTransform(poppoints,proj4string(cities))
writeOGR(poppoints[poppoints$pop>0,],paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Data/cities/'),'poppoints',driver='ESRI Shapefile')

# overlay in qgis? - not efficient here
#citiesinds = over(cities,poppoints)
# 

zipspop = readOGR(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Data/cities/'),'zip_pop')
zips = addresses %>% group_by(zip) %>% summarize(nstations = n())
zips$zip = as.numeric(trim(as.character(zips$zip)))
zipspop = zipspop@data
zipspop$zip = as.numeric(trim(as.character(zipspop$ZCTA5CE10))) 
zips = left_join(zips,zipspop,by=c('zip'='zip'))
zips=zips[!is.na(zips$zip)&!is.na(zips$nstations)&!is.na(zips$totalpop),]

#popthqs = c(0.0,0.5,0.75)
popthqs = seq(from=0.05,to = 0.95,by=0.05)
rho=c();rhomin=c();rhomax=c();popprop=c()
for(popthq in popthqs){
  q = quantile(zips$totalpop,c(popthq))
  currentzips = zips[zips$totalpop>q,]
  popprop=append(popprop,sum(currentzips$totalpop)/sum(zips$totalpop))
  rhotest = cor.test(currentzips$nstations,currentzips$totalpop)
  rho = append(rho,rhotest$estimate);rhomin = append(rhomin,rhotest$conf.int[1]);rhomax=append(rhomax,rhotest$conf.int[2])
}
g=ggplot(data.frame(quantile=popthqs,rho=rho,rhomin=rhomin,rhomax=rhomax,population=popprop),aes(x=quantile,y=rho))
g+geom_point()+geom_line()+geom_errorbar(ymin=rhomin,ymax=rhomax)+ylim(c(0.0,1.0))+
  geom_line(aes(x=quantile,y=population),color=2)
ggsave(file=paste0(resdir,'corr_zip_pop-stations.png'),width=18,height=15,units='cm')



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
#moran_days_data = data.frame(rho=autocorrs,day=strptime(as.character(days),format='%Y%m%d'),decay=decays)
moran_days_data = data.frame(rho=autocorrs,day=as.numeric(as.character(days)),decay=decays)
save(moran_days_data,file='data/moran_days_data.RData')
write.csv(moran_days_data,file='data/moran_days_data.csv',row.names = F)

g=ggplot(moran_days_data,aes(x=day,y=rho,color=as.character(decay),group=as.character(decay)))
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
#moran_decay_weeks_data = data.frame(rho=autocorrs,week=strptime(as.character(alldays[days]),format='%Y%m%d'),decay=decays)
moran_decay_weeks_data = data.frame(rho=autocorrs,week=as.numeric(as.character(alldays[days])),decay=decays)
save(moran_decay_weeks_data,file='data/moran_decay_weeks_data.RData')
write.csv(moran_decay_weeks_data,file='data/moran_decay_weeks_data.csv',row.names = F)

g=ggplot(moran_decay_weeks_data,aes(x=decay,y=rho,color=week,group=week))
g+geom_point()+geom_line()+scale_x_log10()+xlab('Spatial autocorrelation range')+ylab("Moran index")+scale_colour_datetime(name='Week')+
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




