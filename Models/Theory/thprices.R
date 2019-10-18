
setwd(paste0(Sys.getenv('CS_HOME'),'/EnergyPrice/Models/Theory'))

library(GA)
library(doParallel)

#'
#'
solvePrices <- function(unit_price,transportation_cost,num_stations,density,minPrice=0.001,maxPrice=10,iters=1000,parallel=4,costFunction=function(d){return(d^2)}){
  theta <- function(j,prices){
    return(((prices[((j+1)%%length(prices))+1]-prices[(j%%length(prices))+1])/((prices[((j+1)%%length(prices))+1]+prices[(j%%length(prices))+1])*transportation_cost) + 2*pi*j/num_stations + (2*pi*prices[((j+1)%%length(prices))+1])/((prices[((j+1)%%length(prices))+1]+prices[(j%%length(prices))+1])*num_stations))%%(2*pi))
  }
  
  objective <- function(prices){
    thetas=c();
    for(j in 1:(num_stations+1)){thetas[j]=theta(j,prices)}
    cumsum = 0
    for(j in 1:num_stations){
      thetamin = thetas[j];thetamax = thetas[(j+1)]
      densindmin = (floor(length(density)*thetamin/(2*pi))%%length(density))+1
      densindmax = (floor(length(density)*thetamax/(2*pi))%%length(density))+1
      pops = ifelse(densindmin<=densindmax,density[densindmin:densindmax],density[c(1:densindmax,densindmin:length(density))])
      pop = sum(pops)*(2*pi/length(density))
      pj = prices[j];pjp = prices[((j+1)%%length(prices))+1];pjm=prices[((j-1)%%length(prices))+1]
      intprice = (2 / transportation_cost + 2*pi/num_stations)*(pj - unit_price)*((pjp*density[densindmax])/((pj + pjp)^2)+(pjm*density[densindmin])/((pj + pjm)^2))
      cumsum = cumsum + costFunction(pop - intprice)
    }
    return(cumsum)
  }
  
  optimized <- ga(type = "real-valued", fitness =  function(p) -objective(p),
           lower = rep(minPrice,num_stations), upper = rep(maxPrice,num_stations), 
           popSize = 50, maxiter = iters,parallel = parallel)
  return(optimized@solution)
}

#test
#iters=10
#repets=50

iters=10000
repets=50

mprice=2
#for(mprice in c(1.0,2.0,10)){} # set a thematic realistic value (difficulties to converge otherwise)
nstations = c(10,20)#,100)


cl <- makeCluster(50,outfile='log')
registerDoParallel(cl)


for(nstation in nstations){
    uniformdensity = rep(1,10000)/10000
    #uniformprices=list()
    #for(k in 1:repets){
    #  uniformprices[[k]] <- solvePrices(0.8,1,nstation,uniformdensity,minPrice=0.01,maxPrice=mprice,iters=1000)
    #}
    # parallelize GAs
    uniformprices <- foreach(k=1:repets) %dopar% {
       library(GA)
       return(solvePrices(0.8,1,nstation,uniformdensity,minPrice=0.01,maxPrice=mprice,iters=iters,parallel=FALSE))
    }
    save(uniformprices,file=paste0('res/computed/uniform_maxprice',mprice,'_nstation',nstation,'_',format(Sys.time(), "%Y%m%d_%H%M%S"),'.RData'))
}



for(nstation in nstations){
    tentdensity = c(seq(1,5000,by=1),seq(5000,1,by=-1));tentdensity=tentdensity/sum(tentdensity)
    #tentprices=list()
    #for(k in 1:repets){
    #  show(k)
    #  tentprices[[k]] <- solvePrices(0.8,1,nstation,tentdensity,minPrice=0.01,maxPrice=mprice,iters=10000)#,costFunction=function(d){return((d*10)^2)})
    #}
    tentprices <- foreach(k=1:repets) %dopar% {
       library(GA)
       return(solvePrices(0.8,1,nstation,tentdensity,minPrice=0.01,maxPrice=mprice,iters=iters,parallel = FALSE))
    }
  save(tentprices,file=paste0('res/computed/linear_maxprice',mprice,'_nstation',nstation,'_',format(Sys.time(), "%Y%m%d_%H%M%S"),'.RData'))
}


for(nstation in nstations){
  expdec = exp(-(1:5000)/500)
  expdensity = c(rev(expdec),expdec);expdensity=expdensity/sum(expdensity)
  #expprices=list()
  #for(k in 1:20){
  #  expprices[[k]] <- solvePrices(0.8,1,nstation,expdensity,minPrice=0.01,maxPrice=mprice,iters=10000)#,costFunction=function(d){return((d*10)^2)})
  #}
  expprices <- foreach(k=1:repets) %dopar% {
     library(GA)
     return(solvePrices(0.8,1,nstation,expdensity,minPrice=0.01,maxPrice=mprice,iters=iters,parallel=FALSE))
  }
  save(expprices,file=paste0('res/computed/exp_maxprice',mprice,'_nstation',nstation,'_',format(Sys.time(), "%Y%m%d_%H%M%S"),'.RData'))
}




