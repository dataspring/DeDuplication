library(shiny)
library(DT)

#define UI for application 
shinyUI(navbarPage("Product Hierarchy Matching",
                   tabPanel("Input Files",
                            sidebarLayout(
                              sidebarPanel(
                                id = "tab1-side-panel",
                                h3("Step 1: Upload Files, Step 2: Process"),
                                h4("Select File Parameters:"),
                                checkboxInput('header', 'Header', TRUE),
                                radioButtons('sep', 'Separator',
                                             c(Tab='\t',
                                               Comma=',',
                                               Semicolon=';'
                                               ),
                                             '\t'),
                                radioButtons('quote', 'Quote',
                                             c(None='',
                                               'Double Quote'='"',
                                               'Single Quote'="'"),
                                             '"'),
                                tags$hr(),
                                h4("Choose Input Files:"),
                                h5("Of header type: L01_DESC |TAB| LO2_DESC"),
                                fileInput('file1', 'Choose Source File',
                                          accept=c('text/csv', 
                                                   'text/comma-separated-values,text/plain', 
                                                   '.csv')),
                                tags$hr(),
                                h5("Of header type: L01 |TAB| LO2"),
                                fileInput('file2', 'Choose Comparision File',
                                          accept=c('text/csv', 
                                                   'text/comma-separated-values,text/plain', 
                                                   '.csv')),
                                tags$hr()
                                
                              ),
                              mainPanel(
                                id = "tab1-main-panel",
                                verticalLayout(
                                div(DT::dataTableOutput('contentsInput')),
                                div(DT::dataTableOutput('contentsCompr'))
                                )
                              )
                            )
                   ),
                   tabPanel("Process Files and Results", 
                            sidebarLayout(sidebarPanel(
                                  id = "tab2-side-panel",
                                  h4("Select Distance Ensemble:"),
                                  #distance.methods<-c('osa','lv','dl','hamming','lcs','qgram','cosine','jaccard','jw')
#                                   checkboxInput('osa', 'osa', TRUE),  
#                                   checkboxInput('lv', 'lv', TRUE),
#                                   checkboxInput('dl', 'dl', TRUE),
#                                   checkboxInput('osa', 'hamming', TRUE),
#                                   checkboxInput('lcs', 'lcs', TRUE),
#                                   checkboxInput('qgram', 'qgram', TRUE),
#                                   checkboxInput('cosine', 'cosine', TRUE),
#                                   checkboxInput('jaccard', 'jaccard', TRUE),
#                                   checkboxInput('jw', 'jw', TRUE),


                                    checkboxGroupInput('show_dists', 'Distance Metrics to Use:',
                                                       c('osa','lv','dl','hamming','lcs','qgram','cosine','jaccard','jw', 'soundex'), 
                                                       selected = c('osa','lv','dl','hamming','lcs','qgram','cosine','jaccard','jw', 'soundex')
                                  ),

                                  tags$hr(),
                                  h4("Click Match button to start matching product hierarchy:"),
                                  #button to run a long process
                                  actionButton("process", "Match!"),                            
                                  tags$hr(),
                                  h5("Click Reset button to refresh and start all again"),
                                  actionButton("reset_input", "Reset!!")                            
                              ),
                              mainPanel(
                                id = "tab2-main-panel",
                                verticalLayout(
                                  h4("Status Message:"),
                                  textOutput("statusMessage"),
                                  hr(),
                                  conditionalPanel(condition="input.process > 0 && $('html').hasClass('shiny-busy')",h5("Please Wait...may take a minute or two")),
                                  #
                                  #tags$img(src = "http://www.ajaxload.info/images/exemples/35.gif",id = "loading-spinner")
                                  hr(),
                                  h4("As Compared to Matched Records for Accuracy"),
                                  textOutput("matchMessage"),
                                  tags$head(tags$style("#matchMessage{color: red;font-size: 20px;font-style: italic;}")),  
                                  hr(),
                                  div(DT::dataTableOutput('matchedCompr')),                                  
                                  hr(),
                                  h4("Matched Product Hierarchy Records"),
                                  div(DT::dataTableOutput('matched'))
                                )
                              )
                            )
                    )
))