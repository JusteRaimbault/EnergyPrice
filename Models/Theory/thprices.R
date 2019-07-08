
setwd(paste0(Sys.getenv('CS_HOME'),'/EnergyPrice/Models/Theory'))

library(GA)
library(ggplot2)

source(paste0(Sys.getenv('CS_HOME'),'/Organisation/Models/Utils/R/plots.R'))

#'
#'
solvePrices <- function(unit_price,transportation_cost,num_stations,density,minPrice=0.001,maxPrice=10,iters=1000,costFunction=function(d){return(d^2)}){
  theta <- function(j,prices){
    return(((prices[((j+1)%%length(prices))+1]-prices[(j%%length(prices))+1])/((prices[((j+1)%%length(prices))+1]+prices[(j%%length(prices))+1])*transportation_cost) + 2*pi*j/num_stations + (2*pi*prices[((j+1)%%length(prices))+1])/((prices[((j+1)%%length(prices))+1]+prices[(j%%length(prices))+1])*num_stations))%%(2*pi))
  }
  
  objective <- function(prices){
    thetas=c();
    for(j in 1:(num_stations+1)){thetas[j]=theta(j-1,prices)}
    cumsum = 0
    for(j in 1:num_stations){
      thetamin = thetas[j];thetamax = thetas[j+1]
      densindmin = (floor(length(density)*thetamin/(2*pi))%%length(density))+1
      densindmax = (floor(length(density)*thetamax/(2*pi))%%length(density))+1
      pops = ifelse(densindmin<=densindmax,density[densindmin:densindmax],density[c(1:densindmax,densindmin:length(density))])
      pop = sum()*(2*pi/length(density))
      pj = prices[j];pjp = prices[((j+1)%%length(prices))+1];pjm=prices[((j-1)%%length(prices))+1]
      intprice = (2 / transportation_cost + 2*pi/num_stations)*(pj - unit_price)*((pjp*density[densindmax])/((pj + pjp)^2)+(pjm*density[densindmin])/((pj + pjm)^2))
      cumsum = cumsum + costFunction(pop - intprice)
    }
    return(cumsum)
  }
  
  optimized <- ga(type = "real-valued", fitness =  function(p) -objective(p),
           lower = rep(minPrice,num_stations), upper = rep(maxPrice,num_stations), 
           popSize = 50, maxiter = iters,parallel = 4)
  return(optimized)
}



#for(mprice in c(1.0,2.0,10)){
mprice=2
  for(nstation in c(10,20,100)){
uniformdensity = rep(1,10000)
uniformprices=list()
for(k in 1:20){
uniformprices[[k]] <- solvePrices(0.8,1,nstation,uniformdensity,minPrice=0.01,maxPrice=mprice,iters=1000)
}
save(uniformprices,file=paste0('res/uniform_maxprice',mprice,'_nstation',nstation,'.RData'))
#plot(c(uniformprices@solution),type='l')
}
#}

#for(mprice in c(1.0,2.0,10)){
mprice=2;#nstation=100
  for(nstation in c(10,20)){#,100)){
tentdensity = c(seq(1,1000,by=1),seq(1000,1,by=-1))
tentprices=list()
for(k in 1:20){
  show(k)
tentprices[[k]] <- solvePrices(0.8,1,nstation,tentdensity,minPrice=0.01,maxPrice=mprice,iters=10000)#,costFunction=function(d){return((d*10)^2)})
}
save(tentprices,file=paste0('res/linear_maxprice',mprice,'_nstation',nstation,'.RData'))
#plot(c(tentprices@solution),type='l')
}
#}
#load('res/linear_maxprice2_nstation100.RData')
#plot(rowMeans(sapply(tentprices,function(l){l@solution})))

mprice=2;#nstation=100
for(nstation in c(10,20,100)){
expdec = 1000*exp(-(0:1000)/100)
expdensity = c(rev(expdec),expdec)
expprices=list()
for(k in 1:20){
expprices[[k]] <- solvePrices(0.8,1,nstation,expdensity,minPrice=0.01,maxPrice=mprice,iters=10000)#,costFunction=function(d){return((d*10)^2)})
}
save(expprices,file=paste0('res/exp_maxprice',mprice,'_nstation',nstation,'.RData'))
}
#plot(c(expprices@solution),type='l')


### 
# data in long format
allprices = data.frame()
mprice=2;reps=20
for(nstation in c(10,20,100)){
  load(paste0('res/uniform_maxprice',mprice,'_nstation',nstation,'.RData'))
  load(paste0('res/linear_maxprice',mprice,'_nstation',nstation,'.RData'))
  load(paste0('res/exp_maxprice',mprice,'_nstation',nstation,'.RData'))
  allprices = rbind(allprices,
                    cbind(price=c(sapply(uniformprices,function(l){l@solution})),
                          angle = rep(1:nstation,reps)*360/nstation,
                          stations=rep(nstation,nstation*reps),
                          type='uniform'
                    ),
                    cbind(price=c(sapply(tentprices,function(l){l@solution})),
                          angle = rep(1:nstation,reps)*360/nstation,
                          stations=rep(nstation,nstation*reps),
                          type='linear'
                    ),
                    cbind(price=c(sapply(expprices,function(l){l@solution})),
                          angle = rep(1:nstation,reps)*360/nstation,
                          stations=rep(nstation,nstation*reps),
                          type='exponential'
                    )
                    )
}
for(numcol in c("price","angle","stations")){allprices[,numcol]=as.numeric(as.character(allprices[,numcol]))}

allprices$stations = as.character(allprices$stations)

g=ggplot(allprices,aes(x=angle,y=price,color=stations,group=stations))
g+stat_smooth(method='loess',span = 0.5)+facet_wrap(~type)
# beurk

sres = allprices %>% group_by(angle,stations,type) %>% summarize(priceSd = sd(price),price=mean(price),count=n())
sres$stations = as.character(sres$stations)
g=ggplot(sres,aes(x=angle,y=price,color=stations,group=stations))
g+geom_point()+geom_line()+geom_errorbar(aes(ymin=price-1.96*priceSd/sqrt(count),ymax=price+1.96*priceSd/sqrt(count)))+facet_wrap(~type)+
  geom_line(data=data.frame(angle=(1:length(expdensity))*360/length(expdensity),price=(expdensity-min(expdensity))/(max(expdensity)-min(expdensity))*0.2+1,type=rep('exponential',length(expdensity))),mapping=aes(x=angle,y=price),color='black',linetype=3,inherit.aes =F)+
  geom_line(data=data.frame(angle=(1:length(uniformdensity))*360/length(uniformdensity),price=uniformdensity,type=rep('uniform',length(uniformdensity))),mapping=aes(x=angle,y=price),color='black',linetype=3,inherit.aes =F)+
  geom_line(data=data.frame(angle=(1:length(tentdensity))*360/length(tentdensity),price=(tentdensity-min(tentdensity))/(max(tentdensity)-min(tentdensity))*0.2+1,type=rep('linear',length(tentdensity))),mapping=aes(x=angle,y=price),color='black',linetype=3,inherit.aes =F)+
  stdtheme
ggsave(file='res/thmodel_ga_aggreg_all.png',width=30,height=25,units='cm')




