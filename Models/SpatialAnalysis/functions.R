
library(cartography)
library(classInt)

# functions


getLinearModels<-function(yvar,vars,nvars){
  # brute force with enumerating all sets
  varsets =list(c())
  for(i in 1:nvars){
    newsets = list();j=1
    for(prevset in varsets){
      for(var in vars){
        newsets[[j]]=union(prevset,c(var));j=j+1
      }
    }
    k=1;varsets=list()
    for(j1 in 1:length(newsets)){
      toadd=TRUE
      if(length(varsets)>0){
        for(j2 in 1:length(varsets)){
          toadd=toadd&(!setequal(newsets[[j1]],varsets[[j2]]))
        }
      }
      if(toadd){varsets[[k]]=newsets[[j1]];k=k+1}
    }
    #show(varsets)
  }
  res=c()
  for(varset in varsets){
    if(length(varset)==nvars){
      currentmodel=paste0(yvar,"~",varset[1])
      if(length(varset)>1){for(var in varset[2:length(varset)]){currentmodel=paste0(currentmodel,"+",var)}}
      res=append(res,currentmodel)
    }
  }
  return(res)
}


getPeriodPrices<-function(){
  sdata = data.frame(countydata[countydata$type=="Regular",] %>% group_by(countyid) %>% summarise(price=mean(meanprice)))
  rownames(sdata)<-as.character(sdata$countyid)
  prices = sdata[counties$GEOID,2];prices[is.na(prices)]=0
  return(prices)
}


mapCounties<-function(data,variable,filename,title,legendtitle,layer=counties,extent=extent,withLayout=T,legendRnd=2,pdf=T,divergentColors=T){
  extent <- readOGR(paste0(Sys.getenv("CS_HOME"),'/EnergyPrice/Data/processed/processed_20170320/gis'),layer = 'extent',stringsAsFactors = FALSE)
  layer$GEOID=counties$GEOID
  
  if(pdf==T){
    pdf(file=paste0(resdir,filename,'.pdf'),width=10,height=5.5)#paper='a4r')
  }else{
    png(file=paste0(resdir,filename,'.png'),width=10,height=6,units='cm',res=300)
  }
    
  if(withLayout){par(mar = c(0.4,0.4,2,0.4))}else{par(mar = c(0.4,0.4,0.4,0.4))}
  

  layoutLayer(title = ifelse(withLayout,title,""), sources = "",
              author = "", col = ifelse(withLayout,"grey","white"), coltitle = "black", theme = NULL,
              bg = NULL, scale=NULL , frame = withLayout, north = F, south = FALSE,extent=extent)
  
  breaks=classIntervals(data[,variable],20)
  
  plot(states, border = NA, col = "white",add=T)
  
  if(divergentColors==T){
    cols <- carto.pal(pal1 = "green.pal",n1 = 10, pal2 = "red.pal",n2 = 10)
  }else{
    cols <- carto.pal( pal1 = "red.pal",n1 = 20)
  }
  
  choroLayer(spdf = layer,spdfid = "GEOID",
             df = data,dfid = 'countyid',
             var=variable,
             col=cols,breaks=breaks$brks,
             add=TRUE,lwd = 0.01,
             legend.pos = "n"
  )
  legendChoro(pos = "left",title.txt = legendtitle,
              title.cex = 0.8, values.cex = 0.6, breaks$brks, cols, cex = 0.7,
              values.rnd = legendRnd, nodata = TRUE, nodata.txt = "No data",
              nodata.col = "white", frame = FALSE, symbol = "box"
  )
  plot(states,border = "grey20", lwd=0.75, add=TRUE)
  
  dev.off()
  
}


centroid<-function(polygons){
  coords=matrix(0,0,2)
  for(j in 1:length(polygons@Polygons)){
    coords=rbind(coords,polygons@Polygons[[j]]@coords)
  }
  return(colSums(coords)/nrow(coords))
}


weightMatrix<-function(decay,layer){
  n=length(layer)
  points=matrix(0,n,2)
  for(i in 1:n){
    points[i,]=centroid(layer@polygons[[i]])
  }
  d = spDists(points,longlat=TRUE)
  w = exp(-d/decay)
  diag(w)<-0
  return(w)
}


autocorr<-function(x,w,m){
  n=length(x)
  cx = x - mean(x)
  cxvec=matrix(cx,nrow=n,ncol=1)
  normalization = (w%*%matrix(rep(1,n),nrow=n,ncol=1))*(m%*%(cxvec*cxvec))
  return(((matrix(data = rep(cx,n),ncol = n,nrow = n,byrow = FALSE)*w)%*%cxvec)/normalization)
}

#d[24,2548]
#plot(counties)
#plot(counties[c(24,2548),],col='blue',add=TRUE)
# TODO : check in mile 4158 if consistent

# 4584 km
# miles (google maps by road) 3440 miles = 5500km
# : great circle distance, ok ?








