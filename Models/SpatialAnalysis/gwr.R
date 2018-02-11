
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

resdir <- paste0(Sys.getenv('CS_HOME'),'/EnergyPrice/Results/SpatialAnalysis/gwr/')


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

kernels = c("bisquare","exponential","gaussian","boxcar")

aics=c();models=c();r2=c();bws=c();ckernels=c();approaches=c()
for(i in 1:5){
  modelstotest = getLinearModels(yvar,vars,i)
  for(modelstr in modelstotest){
    show(modelstr)
    for(kernel in kernels){
      bwcv = bw.gwr(modelstr,data=counties,approach="CV", kernel=kernel,adaptive=T)
      gwcv <- gwr.basic(modelstr,data=counties, bw=bwcv,kernel=kernel,adaptive=T)
      aics=append(aics,gwcv$GW.diagnostic$AICc);
      r2=append(r2,gwcv$GW.diagnostic$gwR2.adj);bws=append(bws,bwcv)
      bwaic = bw.gwr(modelstr,data=counties,approach="AIC", kernel=kernel,adaptive=T)
      gwaic <- gwr.basic(modelstr,data=counties, bw=bwaic,kernel=kernel,adaptive=T)
      aics=append(aics,gwaic$GW.diagnostic$AICc);
      r2=append(r2,gwaic$GW.diagnostic$gwR2.adj);bws=append(bws,bwaic)
      models=append(models,rep(modelstr,2));ckernels=append(ckernels,rep(kernel,2));approaches=append(approaches,c("cv","aic"))
    }
  }
}
  
# find the best model
selec = data.frame(aic=aics,model=models,r2=r2,bw=bws,kernel=ckernels,approach=approaches)
#write.table(selec,file=paste0(resdir,'modelselec_all.csv'),sep=";",col.names = T,row.names = F,quote=F)
selec = read.csv(file=paste0(resdir,'modelselec_all.csv'),sep=";",header=T)


# with AIC bandwidth
bestaic = aics[aics==min(aics)] # 2904.743 , price~income+percapjobs 
bestr2 = r2[r2==max(r2)] # 0.285386 , price~income+percapjobs 
bws[aics==min(aics)]


# with Cross-validated bandwidth
bestaic = aics[aics==min(aics)] # 2921.722 , price~income+percapjobs 
bestr2 = r2[r2==max(r2)] # 0.2703091 , price~income+population+percapjobs
r2["price~income+percapjobs"] # 0.264815
aics["price~income+population+percapjobs"] # 2926.552

# BEST model for aic bandwidth is : price~income+percapjobs , both for aic and r2
#write.table(data.frame(model=models,aic=aics,r2=r2),file=paste0(resdir,'gwr/modelselec.csv'),sep=";",col.names = T,row.names = F,quote=F)
#write.table(data.frame(model=models,aic=aics,r2=r2),file=paste0(resdir,'gwr/modelselec_cv.csv'),sep=";",col.names = T,row.names = F,quote=F)


# TODO mean(bestaic - aic)
# TODO give distance range corresponding to bandwidth
# TODO test shape of kernel ?

modelstr="price~income+percapjobs"
bwbest = bw.gwr(modelstr,data=counties,approach="AIC", kernel="bisquare",adaptive=T)
gwbest <- gwr.basic(modelstr,data=counties, bw=bwbest,kernel="bisquare",adaptive=T)
gwbest$SDF$countyid = counties$GEOID
mapCounties(gwbest$SDF@data,"income",'gwr/gwr_best_betaincome','','beta_income',layer=gwbest$SDF,withLayout = F)
mapCounties(gwbest$SDF@data,"percapjobs",'gwr/gwr_best_betapercapjobs','','beta_percapjobs',layer=gwbest$SDF,withLayout = F)
mapCounties(gwbest$SDF@data,"residual",'gwr/gwr_best_residual','','residual',layer=gwbest$SDF,withLayout = F)
mapCounties(gwbest$SDF@data,"Local_R2",'gwr/gwr_best_LocalR2','','Local_R2',layer=gwbest$SDF,withLayout = F)

# best with cross-validation for r2
modelstr="price~income+population+percapjobs"
bwbest = bw.gwr(modelstr,data=counties,approach="CV", kernel="bisquare",adaptive=T)
gwbest <- gwr.basic(modelstr,data=counties, bw=bwbest,kernel="bisquare",adaptive=T)
gwbest$SDF$countyid = counties$GEOID
mapCounties(gwbest$SDF@data,"income",'gwr/gwr_best_betaincome','','beta_income',layer=gwbest$SDF,withLayout = F)
mapCounties(gwbest$SDF@data,"percapjobs",'gwr/gwr_best_betapercapjobs','','beta_percapjobs',layer=gwbest$SDF,withLayout = F)
mapCounties(gwbest$SDF@data,"residual",'gwr/gwr_best_residual','','residual',layer=gwbest$SDF,withLayout = F)
mapCounties(gwbest$SDF@data,"Local_R2",'gwr/gwr_best_LocalR2','','Local_R2',layer=gwbest$SDF,withLayout = F)


#########
## Best model with all kernels
#2900.286 price~income+wage+percapjobs 0.2710871 22 gaussian      aic
# selec$aic-min(selec$aic) : median = 122
#
# mean(selec[selec$model=="price~income+wage+percapjobs"&selec$approach=="aic",1]) = 2932.644
#
# cor(counties@data[,3:ncol(counties@data)])
#

modelstr="price~income+wage+percapjobs"
bwbest = bw.gwr(modelstr,data=counties,approach="AIC", kernel="gaussian",adaptive=T)
gwbest <- gwr.basic(modelstr,data=counties, bw=bwbest,kernel="gaussian",adaptive=T)
gwbest$SDF$countyid = counties$GEOID
mapCounties(gwbest$SDF@data,"income",'gwr_allbest_betaincome','',expression(beta[income]),layer=gwbest$SDF,withLayout = F,legendRnd = 7)
mapCounties(gwbest$SDF@data,"percapjobs",'gwr_allbest_betapercapjobs','',expression(beta[percapjobs]),layer=gwbest$SDF,withLayout = F,legendRnd = 2)
mapCounties(gwbest$SDF@data,"wage",'gwr_allbest_wage','',expression(beta[wage]),layer=gwbest$SDF,withLayout = F,legendRnd = 7)
mapCounties(gwbest$SDF@data,"residual",'gwr_allbest_residual','','Residual',layer=gwbest$SDF,withLayout = F)
mapCounties(gwbest$SDF@data,"Local_R2",'gwr_allbest_LocalR2','','Local R2',layer=gwbest$SDF,withLayout = F)


# write data to a single csv
# write.table(data.frame(counties@data,gwbest$SDF[,c("Intercept","income","wage","percapjobs","residual","Local_R2")]),file=paste0(resdir,'counties_gwrbest.csv'),sep=";",row.names=F,col.names=T,quote=F)
# statedata = joineddata[,c(1,5,6,10:14)];names(statedata)<-c("StateID","GEOID","name","income","jobs","wage","population","percapjobs")
# statedata = as.tbl(statedata) %>% group_by(StateID) %>% summarise(income=mean(income),jobs=sum(jobs),wage=mean(wage),population=sum(population),percapjobs=mean(percapjobs))
#  write.table(statedata,file=paste0(resdir,'stateaggregsocioeco.csv'),sep=";",row.names=F,col.names=T,quote=F)


## effective dim of variables
cor(counties@data[,3:ncol(counties@data)])
mat = counties@data[,3:ncol(counties@data)]
for(j in 1:ncol(mat)){mat[,j]=(mat[,j]-min(mat[,j]))/(max(mat[,j])-min(mat[,j]))}
summary(prcomp(mat))

# average spatial range corresponding to optimal bandwidth
d=spDists(counties,longlat = T)
neighdists = apply(d,1,function(r){mean(sort(r)[2:(bwbest+1)])})
median(neighdists) #  77.7379
quantile(neighdists,0.75)-quantile(neighdists,0.25) # 30.20168







