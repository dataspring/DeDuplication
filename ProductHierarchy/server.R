# Install function for packages    
packages<-function(x){
  x<-as.character(match.call()[[2]])
  if (!require(x,character.only=TRUE)){
    install.packages(pkgs=x,repos="http://cran.r-project.org")
    require(x,character.only=TRUE)
  }
}
packages(shiny)
packages(DT)
packages(stringdist)
packages(sqldf)
packages(shinyjs)


library(shiny)
library(DT)
library(stringdist)
library(sqldf)
library(shinyjs)



#Define server logic required to run histo
shinyServer(function(input, output){
  
  dataFolder <- "prodhier"
  sourceFile <- "sourcefile.txt"
  comprFile <- "comprfile.txt"
  matchFile <- "matched.txt"
  matchComprFile <- "match-accuracy.txt"
  
  
  observeEvent(input$reset_input, {
    shinyjs::reset("tab2-side-panel")
    #shinyjs::reset("tab2-main-panel")
    shinyjs::reset("tab1-side-panel")
    #shinyjs::reset("tab1-main-panel")   
    vals$statusMsg <- '' 
    vals$matchMsg <- '' 
    vals$matchedDS <- NULL
    comprmatch <- sqldf("Select 0 as Match, '' as SourceLo1, ''  as SourceLo2, '' as CompLo1, ''  as CompLo2")
    comprmatch <- comprmatch[0,]
    vals$comprMatched <- comprmatch
    
  })

  #------------------ check for directory presence if not create and return it 
  getDataDir <- function(folderName){
    
    #--------- create unilever first -------------------
    mainDir <- getwd()
    subDir <- "nachiuni"
    dataWD <-  paste(mainDir,'/',subDir, sep="")
    dir.create(file.path(mainDir, subDir), showWarnings = FALSE)
    # --------- create subsequent folders
    mainDir <- dataWD
    subDir <- folderName
    dataWD <-  paste(mainDir,'/',subDir, sep="")
    dir.create(file.path(mainDir, subDir), showWarnings = FALSE)
    
    return(dataWD)
  }

  
  vals <- reactiveValues(statusMsg = '', matchMsg = '', matchedDS = NULL, comprMatched = NULL)
  output$statusMessage <- renderText({
    vals$statusMsg
  })
  
  output$matchMessage <- renderText({
    vals$matchMsg
  })
  
  
  
  #------------------------ intialize the data table for formatStyle issue upfront -----------------------
  comprmatch <- sqldf("Select 0 as Match, '' as SourceLo1, ''  as SourceLo2, '' as CompLo1, ''  as CompLo2")
  comprmatch <- comprmatch[0,]
  vals$comprMatched <- comprmatch
  #--------------------------------------------------------------------------
  
  output$matched <- DT::renderDataTable({
    DT::datatable(vals$matchedDS, options = list(pageLength = 5,autoWidth = TRUE))
  })
  
  output$matchedCompr <- DT::renderDataTable({
    DT::datatable(vals$comprMatched, options = list(pageLength = 5,autoWidth = TRUE)) %>% 
      formatStyle(
        'Match',
        target = 'row',
        backgroundColor = styleEqual(c(0, 1), c('red','green'))
      ) 

  })
  
  
  getSourceData <- reactive({
    inFile <- input$file1
    if (is.null(inFile)) return(NULL)
    data <- read.csv(inFile$datapath, header=input$header, sep=input$sep, 
                     quote=input$quote)
    #--------- persist the file locally for subsequent use
    fileName <- file.path(getDataDir(dataFolder), sourceFile)
    #print(getDataDir(dataFolder))
    write.table(data, sep="\t",  file=fileName, row.names=FALSE, quote=FALSE)    
    data
  })
  
  
  output$contentsInput <- DT::renderDataTable({
    sourceData <- getSourceData()
    #vals$statusMsg  <- paste('Good to Go - Source Count : ', nrow(sourceData))
    DT::datatable(sourceData, options = list(pageLength = 5,autoWidth = TRUE))
  })
  
  
  getCompareData <- reactive({
    inFile <- input$file2
    if (is.null(inFile)) return(NULL)
    data <- read.csv(inFile$datapath, header=input$header, sep=input$sep, 
                     quote=input$quote)
    #--------- persist the file locally for subsequent use
    fileName <- file.path(getDataDir(dataFolder), comprFile)
    #print(getDataDir(dataFolder))
    write.table(data, sep="\t",  file=fileName, row.names=FALSE, quote=FALSE)    
    data
  })
  
  
  output$contentsCompr <- DT::renderDataTable({
     compData <- getCompareData()
     DT::datatable(compData, options = list(pageLength = 5,autoWidth = TRUE))
  })
  
  
  
  observe({
    if (input$process == 0)
      return()
    
    isolate({

      dir.path <- getDataDir(dataFolder)
      source.file <- file.path(dir.path,sourceFile)                         
      compr.file <- file.path(dir.path,comprFile)
      matched.file <- file.path(dir.path,matchFile)
      matchedCompr.file <- file.path(dir.path,matchComprFile)
      
      if (!file.exists(source.file) | !file.exists(source.file) ) {
        vals$statusMsg <- 'Source File and/or Comparision File Not Found'
      }
      else {
        #---------- Read a locally stored file and start the process -----------
        sourceData <- read.csv(source.file, header=TRUE, sep="\t")
        compData <- read.csv(compr.file, header=TRUE, sep="\t")
        
        vals$statusMsg <- paste('Processing Source File of Record Count : ', nrow(sourceData))
        
        #---------------- start processing -----------------------------
        
        source1<-as.data.frame(as.character(na.omit(unique(sourceData[,c("L01_DESC")]))), stringsAsFactors = FALSE)
        source2<-as.data.frame(as.character(na.omit(unique(sourceData[,c("L02_DESC")]))), stringsAsFactors = FALSE)
        
        colnames(source1) <- "name"
        colnames(source2) <- "name"
        
        #--------------- start parllel processing -------------
#         library("doParallel")
#         cl <- makeCluster(detectCores() - 1)
#         registerDoParallel(cl, cores = detectCores() - 1)
        
        #---------------- start distnace caluclaution  -----------------------------
        vals$statusMsg <- 'Staring ensemble of distances computation'
        
        print(input$show_dists)
        
        distance.methods<-input$show_dists
        dist.methods<-list()
        for(m in 1:length(distance.methods))
        {
          dist.name.enh<-matrix(NA, ncol = length(source2$name),nrow = length(source1$name))
          for(i in 1:length(source2$name)) {
            for(j in 1:length(source1$name)) { 
              dist.name.enh[j,i]<-stringdist(tolower(source2[i,"name"]),tolower(source1[j,"name"]),method = distance.methods[m])      
              #adist.enhance(source2[i,]$name,source1[j,]$name)
            }  
          }
          dist.methods[[distance.methods[m]]]<-dist.name.enh
        }
        
        
        #---------------- start transpose  -----------------------------
        vals$statusMsg <- 'transposing results...'
        
        match.s1.s2.enh<-NULL
        for(m in 1:length(distance.methods)) 
        {
          
          dist.matrix<-as.matrix(dist.methods[[distance.methods[m]]])
          min.name.enh<-apply(dist.matrix, 1, base::min)
          for(i in 1:nrow(dist.matrix))
          {
            s2.i<-match(min.name.enh[i],dist.matrix[i,])
            s1.i<-i
            match.s1.s2.enh<-rbind(data.frame(s1.i=s1.i,s2.i=s2.i,s1name=source1[s1.i,"name"], s2name=source2[s2.i,"name"], adist=min.name.enh[i],method=distance.methods[m]),match.s1.s2.enh)
          }
        }
        match.s1.s2.enh<-match.s1.s2.enh[with(match.s1.s2.enh, order(s1.i)), ]
        
        #------------------- select an ensemble of distance methods that are nearer to s1 strings ---------
        vals$statusMsg <- 'determing comparisions...'
        
        colnames(match.s1.s2.enh) <- c("s2i",  "s1i",   "s2name", "s1name", "adist",  "method")
        
        
        matched.high <- sqldf("Select s1i, s1name, s2name, count(*) AS count from [match.s1.s2.enh] group by s1i, s1name, s2name order by s2name, count DESC",stringsAsFactors = FALSE)
        print(matched.high[matched.high$s2name == 'WALLS COMPLETE DESSERTS CLASSIC TUB 810G',])
        print(matched.high[matched.high$count >=3 & matched.high$count <=5,])
        #use the by function to get the top n rows in each group, 
        #If you want the result to be a data.frame: 
        d <- by(matched.high, matched.high["s2name"], head, n=1)
        matched <- Reduce(rbind, d)
        vals$matchedDS <- matched
        
        write.table(matched, sep="\t",  file=matched.file, row.names=FALSE, quote=FALSE)
        #write.table(compData, sep="\t",  file="compData1.txt", row.names=FALSE, quote=FALSE)         
        
        
        comprmatch <- sqldf("Select 0 as Match, b.s2name as SourceLo1, b.s1name as SourceLo2, a.lo1 as CompLo1, a.lo2 as CompLo2 from matched b, compData a where b.s2name = a.lo1")
        write.table(comprmatch, sep="\t",  file=matchedCompr.file, row.names=FALSE, quote=FALSE)         
        
        comprmatch[comprmatch$SourceLo2 == comprmatch$CompLo2, "Match"] <- 1
        vals$matchMsg = paste('Accuracy calibrated with given matched records : ', nrow(comprmatch[comprmatch$Match == 1,]), ' out of ', nrow(comprmatch), sep="")
        vals$comprMatched <- comprmatch
        
        vals$statusMsg <- paste('Written Matched Records to :',matched.file, 'and comparision against given subset of matched records to', matchedCompr.file, sep=" " )
      
      }
      
      
    })
  })
  
  
  
  

  
  
})