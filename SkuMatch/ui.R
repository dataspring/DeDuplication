library(shiny)
library(DT)

#define UI for application 
shinyUI(navbarPage("SKU Matching",
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
                                h5("Source: Internal DataSet "),
                                h6("Category | Brand | Variant | Form | Package | Size | SKU.Name | Packsize"),
                                fileInput('file1', 'Choose a source file',
                                          accept=c('text/csv', 
                                                   'text/comma-separated-values,text/plain', 
                                                   '.csv')),
                                tags$hr(),
                                h5("Source: Extrenal Nielsen Dataset"),
                                h6("FORM | SUBSEGMENT | Brand | VARIANTA | PACKAGE | Packsize | Long.Description"),
                                fileInput('file11', 'Choose a source file',
                                          accept=c('text/csv', 
                                                   'text/comma-separated-values,text/plain', 
                                                   '.csv')),
                                tags$hr(),
                                h5("Comparision File Subset"),
                                h6("Category | Brand | Variant | Form | Package | Size | SKU.Name | Packsize | Ext_FORM | Ext_SUBSEGMENT | Ext_Brand | Ext_VARIANTA | Ext_PACKAGE | Ext_Packsize | Ext_Long.Description"),
                                fileInput('file2', 'Choose a comparision file',
                                          accept=c('text/csv', 
                                                   'text/comma-separated-values,text/plain', 
                                                   '.csv')),
                                
                                tags$hr()
                                
                              ),
                              mainPanel(
                                id = "tab1-main-panel",
                                verticalLayout(
                                div(DT::dataTableOutput('contentsInput')),
                                div(DT::dataTableOutput('contentsInput2')),
                                div(DT::dataTableOutput('contentsCompr'))
                                )
                              )
                            )
                   ),
                   tabPanel("Process Files and Results", 
                            sidebarLayout(sidebarPanel(
                                  id = "tab2-side-panel",
                                  h4("Select Unsupervised Method"),

                                    checkboxGroupInput('show_algos', 'Algorithm to Use:',
                                                       c('kmeans','bclust'), 
                                                       selected = c('kmeans','bclust')
                                  ),

                                  tags$hr(),
                                  h4("Click Match button to start matching sku entries:"),
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
                                  h5("Confusion Matrix Details"),
                                  textOutput("confusionMatrixUI"),
                                  h4("Confusion Matrix Plot"),
                                  plotOutput("confusionMatrix")
                                  
                                )
                              )
                            )
                    ),
                   tabPanel("Result Files", 
                            sidebarLayout(sidebarPanel(
                              id = "tab3-side-panel",
                              h5("All Result Files")
                            ),
                            mainPanel(
                              id = "tab3-main-panel",
                              verticalLayout(
                                h4("Comaprision Records Re-identified with Original"),
                                div(DT::dataTableOutput('compared')),                                  
                                hr(),
                                h4("Matched SKU Records of Internal vs External DataSet"),
                                div(DT::dataTableOutput('matched'))
                              )
                            )
                            )
                   )
))