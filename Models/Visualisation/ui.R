

shinyUI(navbarPage("Fuel Prices", id="nav",
                   
        tabPanel("Interactive map",
            div(class="outer",
               tags$head(
                 includeCSS("styles.css"),
                    tags$script(HTML(
                      "<script>
                        (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
                          (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
                          m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
                        })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');
                      
                      ga('create', 'UA-40299595-8', 'auto');
                      ga('send', 'pageview');
                      
                      </script>"
                                  ))
                                  ),
                                
                   leafletOutput("map", width="100%", height="100%"),
                                
                                # Shiny versions prior to 0.11 should use class="modal" instead.
                  absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
                     draggable = TRUE, top = 60, left = "auto", right = 20, bottom = "auto",
                     width = 330, height = "auto",  
                     selectInput("day", "day", days)#,
                     #sliderInput(inputId = "time","Time",timeFormat = "%H:%M",min = min(hours),max=max(hours),value=min(hours),step=NULL),
                     #selectInput("var", "Variable", vars)
                                         
                    )#,
                                
                    # plot panel
                  #absolutePanel(id = "plots", class = "panel panel-default", fixed = TRUE,
                  #      draggable = TRUE, top = 400, left = "auto", right = 20, bottom = "auto",
                  #       width = 330, height = "auto",
                  #                            
                  #      plotOutput("dailyCong", height = 200)
                  #              ) 
             
       )
     ),
      conditionalPanel("false", icon("crosshair"))
  )
)



