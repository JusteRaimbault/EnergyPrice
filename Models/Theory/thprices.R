
setwd(paste0(Sys.getenv('CS_HOME'),'/EnergyPrice/Models/Theory'))

library(GA)

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

