


shinyServer(function(input, output, session) {
  
  output$map <- renderLeaflet({
    leaflet() %>%
      addTiles(
        urlTemplate = "//{s}.tiles.mapbox.com/v3/jcheng.map-5ebohr46/{z}/{x}/{y}.png",
        attribution = 'Maps by <a href="http://www.mapbox.com/">Mapbox</a>'
      ) %>%
      setView(lng = -93.85, lat = 37.45, zoom = 4)
  })
  
  countiesInBounds <- reactive({
    if (is.null(input$map_bounds)) return(rep(TRUE,length(counties)))
    bounds <- input$map_bounds
    mapbbox = bbox(SpatialPoints(coords=matrix(c(bounds$west,bounds$north,bounds$west, bounds$south,bounds$east,bounds$north,bounds$east, bounds$south),ncol=2,byrow = TRUE),proj4string = counties@proj4string))
    mapbbox=readWKT(paste0('POLYGON((',bounds$west,' ',bounds$north,',',bounds$east,' ',bounds$north,',',bounds$east,' ',bounds$south,',',bounds$west,' ',bounds$south,',',bounds$west,' ',bounds$north,'))'),p4s = counties@proj4string)
    return(sapply(counties@polygons,function(l){gContains(mapbbox,SpatialPolygons(list(l),proj4string = counties@proj4string))}))
  })
  
  getCurrentData <- reactive({
    # TODO add weekly aggreg ?
    return(countydata[countydata$day==input$day,])
  })
  
  observe({
    currentData = getCurrentData()
    currentCounties = counties[countiesInBounds(),]
    show(paste0('current counties : ',length(currentCounties)))
    prices = currentData$meanprice
    names(prices)<-currentData$countyid
    
    # TODO add color normalization in time / space
    pal <- colorNumeric(c("green","yellow","red"),domain = prices)
 
    show(prices[currentCounties$GEOID])
    
    leafletProxy("map") %>%
      clearShapes() %>%
      addPolygons(data = currentCounties,
                  color = pal(prices[currentCounties$GEOID]),
          fillOpacity=1
      )
    
    show('polygons drawn')
    
  })
  
  
  
})