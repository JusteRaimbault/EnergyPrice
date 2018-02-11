


shinyServer(function(input, output, session) {
  
  output$map <- renderLeaflet({
    leaflet() %>%
      addTiles(
        urlTemplate = "//{s}.tiles.mapbox.com/v3/jcheng.map-5ebohr46/{z}/{x}/{y}.png",
        attribution = 'Maps by <a href="http://www.mapbox.com/">Mapbox</a>'
      ) %>%
      setView(lng = -93.85, lat = 39, zoom = 5)
  })
  
  countiesInBounds <- reactive({
    if (is.null(input$map_bounds)) return(rep(TRUE,length(counties)))
    bounds <- input$map_bounds
    mapbbox = bbox(SpatialPoints(coords=matrix(c(bounds$west,bounds$north,bounds$west, bounds$south,bounds$east,bounds$north,bounds$east, bounds$south),ncol=2,byrow = TRUE),proj4string = counties@proj4string))
    mapbbox=readWKT(paste0('POLYGON((',bounds$west,' ',bounds$north,',',bounds$east,' ',bounds$north,',',bounds$east,' ',bounds$south,',',bounds$west,' ',bounds$south,',',bounds$west,' ',bounds$north,'))'),p4s = counties@proj4string)
    return(sapply(counties@polygons,function(l){gOverlaps(mapbbox,SpatialPolygons(list(l),proj4string = counties@proj4string))|gContains(mapbbox,SpatialPolygons(list(l),proj4string = counties@proj4string))}))
  })
  
  isCountyLevel<-reactive({
    if (is.null(input$map_bounds)){return(FALSE)}
    bounds <- input$map_bounds
    boundsall = bbox(states)
    if((bounds$north-bounds$south)<((boundsall[2,2]-boundsall[2,1])*changeLevelFactor)){
      return(TRUE)
    }else{return(FALSE)}
  })
  
  getCurrentData <- reactive({
    # weekly aggreg -> not optimal, recomputed each time
    firstday=as.numeric(strsplit(input$week,"-")[[1]][1]);lastday=as.numeric(strsplit(input$week,"-")[[1]][2])
    return(list(
      counties=countydata[countydata$day>=firstday&countydata$day<=lastday&countydata$type==input$type,]%>%group_by(countyid)%>%summarise(meanprice=mean(meanprice)),
      states=statedata[statedata$day>=firstday&statedata$day<=lastday&statedata$type==input$type,]%>%group_by(state)%>%summarise(meanprice=mean(meanprice))))
  })
  
  proxy = leafletProxy("map",data=states)
  
  observe({
    currentData = getCurrentData()
    currentCounties = counties[countiesInBounds(),]
    show(paste0(length(currentCounties),' - ',isCountyLevel()))
    #show(paste0('current counties : ',length(currentCounties)))
    
    if(isCountyLevel()){
      data = currentCounties
      prices = currentData$counties$meanprice
      names(prices)<-currentData$counties$countyid
      ids = currentCounties$GEOID
    }else{
      data = states
      prices = currentData$states$meanprice
      names(prices)<-currentData$states$state
      ids=data$GEOID
    }
    
    q = quantile(prices[ids],seq(from=0.05,to=1.0,by=0.05),na.rm = T)
    pal = c(colorRampPalette(c("green", "red"))(20),"#505050")
    colors = pal[sapply(prices[ids],function(p){if(is.na(p)){21}else{which(p<=q&p>c(0,q[1:length(q)-1]))}})]
    
    # TODO add color normalization in time / space
    
   proxy %>% clearShapes()

    for(i in 1:length(data)){
      #show(i)
       #show(dim(states@polygons[[i]]@Polygons[[1]]@coords))
      for(j in 1:length(data@polygons[[i]]@Polygons)){
        proxy %>% addPolygons(
          data=data,
          lng=data@polygons[[i]]@Polygons[[j]]@coords[,1],
          lat=data@polygons[[i]]@Polygons[[j]]@coords[,2],
          weight=2,
          layerId=i,
          color =colors[i],
          fillOpacity=0.7,opacity=0.7
        )
      }
    }
    
  })
  
  
  
})