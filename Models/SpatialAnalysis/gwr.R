
###
# GWR analysis

setwd(paste0(Sys.getenv('CS_HOME'),'/EnergyPrice/Models/SpatialAnalysis'))

library(dplyr)
library(rgdal)
library(GWmodel)

source('functions.R')

# socio-economic variables
countysocioeco <- readOGR(dsn=paste0(Sys.getenv('CS_HOME'),'/EnergyPrice/Data/census/bea009p020_nt00355'),layer = 'bea009p020',stringsAsFactors = FALSE)
counties <- readOGR(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Data/processed/processed_20170320/gis'),layer = 'county_us_metro',stringsAsFactors = FALSE)
# write socioeco data
# names(countysocioeco)[27:32]<- c("name","income","jobs","wage","population","percapjobs")
# write.table(countysocioeco@data,file=paste0(Sys.getenv('CS_HOME'),'/EnergyPrice/Data/census/socioeco.csv'),row.names=F,col.names=T,quote=F,sep=";")

# variables : 
#  - B13_yyyy : per capita income
#  - A34_yyyy : average yearly number of jobs
#  - B34_yyyy : average wage per job
#  - POP_yyyy : population
#  - JOB_yyyy : per capita number of jobs

# merge with counties
joineddata = left_join(counties@data,countysocioeco@data[,c("BEA_FIPS","B13_2008","A34_2008","B34_2008","POP_2008","JOB_2008")],by=c("GEOID"="BEA_FIPS"))
joineddata = joineddata[!duplicated(joineddata),]
joineddata[is.na(joineddata)]=0
counties@data=joineddata[,c(5,6,10:14)];names(counties@data)<-c("GEOID","name","income","jobs","wage","population","percapjobs")
counties$price = getPeriodPrices()

######
# test on full period

# bandwidth (fixed distance)
bwfullaic = bw.gwr(price~income+jobs+wage+population+percapjobs,data=counties,approach="AIC", kernel="bisquare",adaptive=T)
bwfullcv = bw.gwr(price~income+jobs+wage+population+percapjobs,data=counties,approach="CV", kernel="bisquare",adaptive=T)

bwincaic = bw.gwr(price~income,data=counties,approach="AIC", kernel="bisquare",adaptive=T)
bwinccv = bw.gwr(price~income,data=counties,approach="CV", kernel="bisquare",adaptive=T)

# estimate simple models
gwfullaic <- gwr.basic("price~income+jobs+wage+population+percapjobs",data=counties, bw=bwfullaic,kernel="bisquare",adaptive=T)
print(gwfullaic)

gwfullcv <- gwr.basic(price~income+jobs+wage+population+percapjobs,data=counties, bw=bwfullcv,kernel="bisquare",adaptive=T)
print(gwfullcv)

gwincaic <- gwr.basic(price~income,data=counties, bw=bwincaic,kernel="bisquare",adaptive=T)
print(gwincaic)



# map full aic
gwfullaic$SDF$countyid = counties$GEOID
mapCounties(gwfullaic$SDF@data,"income",'gwr_fullaic_betaincome','GWR full aic','beta_income',layer=gwfullaic$SDF,withLayout = F)
mapCounties(gwfullaic$SDF@data,"population",'gwr_fullaic_betapopulation','GWR full aic','beta_population',layer=gwfullaic$SDF)
mapCounties(gwfullaic$SDF@data,"residual",'gwr_fullaic_residual','GWR full aic','residual',layer=gwfullaic$SDF)
mapCounties(gwfullaic$SDF@data,"Local_R2",'gwr_fullaic_LocalR2','GWR full aic','Local_R2',layer=gwfullaic$SDF)

# 

###
# test all models with all variables number

vars=c("income","jobs","wage","population","percapjobs")
yvar="price"


aics=c();models=c();r2=c()
for(i in 1:5){
  modelstotest = getLinearModels(yvar,vars,i)
  for(modelstr in modelstotest){
    show(modelstr)
    bw = bw.gwr(modelstr,data=counties,approach="AIC", kernel="bisquare",adaptive=T)
    gw <- gwr.basic(modelstr,data=counties, bw=bw,kernel="bisquare",adaptive=T)
    aics=append(aics,gw$GW.diagnostic$AICc);
    r2=append(r2,gw$GW.diagnostic$gwR2.adj)
    models=append(models,modelstr)
  }
}
  
# find the best model
names(aics)<-models
names(r2)<-models
bestaic = aics[aics==min(aics)] # 2904.743 
bestr2 = r2[r2==max(r2)] # 0.285386 

# BEST model is : price~income+percapjobs , both for aic and r2
#write.table(data.frame(model=models,aic=aics,r2=r2),file=paste0(resdir,'gwr/modelselec.csv'),sep=";",col.names = T,row.names = F,quote=F)

modelstr="price~income+percapjobs"

bwbest = bw.gwr(modelstr,data=counties,approach="AIC", kernel="bisquare",adaptive=T)
gwbest <- gwr.basic(modelstr,data=counties, bw=bwbest,kernel="bisquare",adaptive=T)

gwbest$SDF$countyid = counties$GEOID
mapCounties(gwbest$SDF@data,"income",'gwr/gwr_best_betaincome','','beta_income',layer=gwbest$SDF,withLayout = F)
mapCounties(gwbest$SDF@data,"percapjobs",'gwr/gwr_best_betapercapjobs','','beta_percapjobs',layer=gwbest$SDF,withLayout = F)
mapCounties(gwbest$SDF@data,"residual",'gwr/gwr_best_residual','','residual',layer=gwbest$SDF,withLayout = F)
mapCounties(gwbest$SDF@data,"Local_R2",'gwr/gwr_best_LocalR2','','Local_R2',layer=gwbest$SDF,withLayout = F)





  


