
setwd(paste0(Sys.getenv('CS_HOME'),'/EnergyPrice/Models/Theory'))

library(ggplot2)

source(paste0(Sys.getenv('CS_HOME'),'/Organisation/Models/Utils/R/plots.R'))


loadLatest <- function(type,mprice,nstation){
  files <- list.files('res/computed')
  prefix = paste0(type,'_maxprice',mprice,'_nstation',nstation,'_')
  load(paste0('res/computed/',sort(files[grep(prefix,files)],decreasing = T)[1]))
  # shitty language damnit
  if(type=='uniform'){return(uniformprices)}
  if(type=='linear'){return(tentprices)}
  if(type=='exp'){return(expprices)}
}


### 
# data in long format
allprices = data.frame()
mprice=2;reps=50
nstations=c(10,20)#,100)

for(nstation in nstations){
  uniformprices=loadLatest('uniform',mprice,nstation)
  tentprices=loadLatest('linear',mprice,nstation)
  expprices=loadLatest('exp',mprice,nstation)
  allprices = rbind(allprices,
                    cbind(price=
                          #c(sapply(uniformprices,function(l){l@solution})),
                          unlist(uniformprices),
                          angle = rep(1:nstation,reps)*360/nstation,
                          stations=rep(nstation,nstation*reps),
                          type='uniform'
                    ),
                     cbind(price=unlist(tentprices),
                             #c(sapply(tentprices,function(l){l@solution})),
                           angle = rep(1:nstation,reps)*360/nstation,
                           stations=rep(nstation,nstation*reps),
                           type='linear'
                     ),
                     cbind(price=unlist(expprices),
                             #c(sapply(expprices,function(l){l@solution})),
                           angle = rep(1:nstation,reps)*360/nstation,
                           stations=rep(nstation,nstation*reps),
                           type='exponential'
                     )
  )
}
for(numcol in c("price","angle","stations")){allprices[,numcol]=as.numeric(as.character(allprices[,numcol]))}

allprices$stations = as.character(allprices$stations)

# densities
uniformdensity = getDensity('uniform')
tentdensity = getDensity('linear')
expdec = getDensity('exp')


#g=ggplot(allprices,aes(x=angle,y=price,color=stations,group=stations))
#g+stat_smooth(method='loess',span = 0.5)+facet_wrap(~type)
# beurk

sres = allprices %>% group_by(angle,stations,type) %>% summarize(priceSd = sd(price),price=mean(price),count=n())
sres$stations = as.character(sres$stations)
g=ggplot(sres,aes(x=angle,y=price,color=stations,group=stations))
g+geom_point()+geom_line()+geom_errorbar(aes(ymin=price-1.96*priceSd/sqrt(count),ymax=price+1.96*priceSd/sqrt(count)))+facet_wrap(~type)+
  geom_line(data=data.frame(angle=(1:length(expdensity))*360/length(expdensity),price=(expdensity-min(expdensity))/(max(expdensity)-min(expdensity))*0.2+1,type=rep('exponential',length(expdensity))),mapping=aes(x=angle,y=price),color='black',linetype=3,inherit.aes =F)+
  geom_line(data=data.frame(angle=(1:length(uniformdensity))*360/length(uniformdensity),price=uniformdensity*length(uniformdensity),type=rep('uniform',length(uniformdensity))),mapping=aes(x=angle,y=price),color='black',linetype=3,inherit.aes =F)+
  geom_line(data=data.frame(angle=(1:length(tentdensity))*360/length(tentdensity),price=(tentdensity-min(tentdensity))/(max(tentdensity)-min(tentdensity))*0.2+1,type=rep('linear',length(tentdensity))),mapping=aes(x=angle,y=price),color='black',linetype=3,inherit.aes =F)+
  stdtheme
ggsave(file='res/thmodel_ga_aggreg_all.png',width=40,height=20,units='cm')




