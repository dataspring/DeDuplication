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
packages(RecordLinkage)
packages(stringr)
#packages(dplyr)
packages(caret)


library(shiny)
library(DT)
library(stringdist)
library(sqldf)
library(shinyjs)
library(RecordLinkage)
library(stringr)
#library(dplyr)
library(caret)



#Define server logic required to run histo
shinyServer(function(input, output){
  
  dataFolder <- "sku"
  sourceFile <- "sourcefile.txt"
  sourceFile2 <- "sourcefile2.txt"
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

  
  vals <- reactiveValues(statusMsg = '', matchMsg = '', confusionMatrixUI='', confMatrix = NULL, matchedDS = NULL, comprMatched = NULL, comparedOnes = NULL)
  vals$confMatrix <- matrix(data=0, nrow = 2, ncol = 2)
  
  output$statusMessage <- renderText({
    vals$statusMsg
  })
  
  output$matchMessage <- renderText({
    vals$matchMsg
  })
  
  output$confusionMatrix <-  renderPlot ({
    fourfoldplot(vals$confMatrix, color = c("#CC6666", "#99CC99"), conf.level = 0, margin = 1, main = "Confusion Matrix")
  })
  
  output$confusionMatrixUI <-  renderText ({
    vals$confusionMatrixUI
  })
  
  
  #------------------------ intialize the data table for formatStyle issue upfront -----------------------
  comprmatch <- sqldf("Select 0 as id1, 0 as id2, 0 as id2Pred, 0 as truth, 0 as pred, 0 as truthvspred")
  comprmatch <- comprmatch[0,]
  vals$comprMatched <- comprmatch
    
  #--------------------------------------------------------------------------
  
  output$matched <- DT::renderDataTable({
    DT::datatable(vals$matchedDS, options = list(pageLength = 5,autoWidth = TRUE))
  })
  
  
  #---------------
  output$compared <- DT::renderDataTable({
    DT::datatable(vals$comparedOnes, options = list(pageLength = 5,autoWidth = TRUE))
  })
  
  
  output$matchedCompr <- DT::renderDataTable({
    DT::datatable(vals$comprMatched, options = list(pageLength = 5,autoWidth = TRUE)) %>% 
      formatStyle(
        'truthvspred',
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
  
  getSourceData2 <- reactive({
    inFile <- input$file11
    if (is.null(inFile)) return(NULL)
    data <- read.csv(inFile$datapath, header=input$header, sep=input$sep, 
                     quote=input$quote)
    #--------- persist the file locally for subsequent use
    fileName <- file.path(getDataDir(dataFolder), sourceFile2)
    #print(getDataDir(dataFolder))
    write.table(data, sep="\t",  file=fileName, row.names=FALSE, quote=FALSE)    
    data
  })
  
  
  
  output$contentsInput <- DT::renderDataTable({
    sourceData <- getSourceData()
    #vals$statusMsg  <- paste('Good to Go - Source Count : ', nrow(sourceData))
    DT::datatable(sourceData, options = list(pageLength = 5,autoWidth = TRUE))
  })
  
  output$contentsInput2 <- DT::renderDataTable({
    sourceData <- getSourceData2()
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
  
  
  #------------------ distance ensemble function -----------------------
  #---------------- function to get the best distance -------------------------
  getMatchingId <- function(src, tar) {
    
    if (nrow(tar) == 1) {
      return (tar)
    }
    
    if (nrow(tar) > 15) {
      return (NULL)
    } 
    
    source1 <- src
    source2 <- tar
    
    names(source1)[names(source1) == 'SKU.Name'] <- 'name'
    names(source2)[names(source2) == 'SKU.Name'] <- 'name'
    
    distance.methods<-c('osa','lv','dl','hamming','lcs','qgram','cosine','jaccard','jw', 'soundex')
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
    
    match.s1.s2.enh<-NULL
    for(m in 1:10) 
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
    
    #------------------- select an ensemble of distance methods that are nearer to s1 strings
    library(sqldf)
    colnames(match.s1.s2.enh) <- c("s2i",  "s1i",   "s2name", "s1name", "adist",  "method")
    
    
    matched.high <- sqldf("Select s1i, s1name, s2name, count(*) AS count from [match.s1.s2.enh] group by s1i, s1name, s2name order by s2name, count DESC",stringsAsFactors = FALSE)
    #use the by function to get the top n rows in each group, 
    #If you want the result to be a data.frame: 
    d <- by(matched.high, matched.high["s2name"], head, n=1)
    matched <- Reduce(rbind, d)
    
    tar[tar$SKU.Name == matched$s1name,]  
    
    
  }
  
  
  #---------------------------------------------------------------------
  
  
  observe({
    if (input$process == 0)
      return()
    
    isolate({

      dir.path <- getDataDir(dataFolder)
      source.file <- file.path(dir.path,sourceFile)                         
      source.file2 <- file.path(dir.path,sourceFile2)                         
      compr.file <- file.path(dir.path,comprFile)
      matched.file <- file.path(dir.path,matchFile)
      matchedCompr.file <- file.path(dir.path,matchComprFile)
      
      if (!file.exists(source.file) | !file.exists(source.file) ) {
        vals$statusMsg <- 'Source File and/or Comparision File Not Found'
      }
      else {
        #---------- Read a locally stored file and start the process -----------
        #sourceData <- read.csv(source.file, header=TRUE, sep="\t")
        #compData <- read.csv(compr.file, header=TRUE, sep="\t")
        
        sku1 <- read.csv(source.file, header=TRUE, sep="\t", stringsAsFactors = FALSE)
        sku2 <- read.csv(source.file2, header=TRUE, sep="\t", stringsAsFactors = FALSE)
        comprSku1 <- read.csv(compr.file, header=TRUE, sep="\t", stringsAsFactors = FALSE)
        
        vals$statusMsg <- paste('Processing Source File of Record Count : ', nrow(sku1))
        
        #---------------- start processing -----------------------------
        
        #------------------ general prep ---------------------------- 
        sku2$SUBSEGMENT <- NULL
        sku1$Size <- NULL 
        sku1$Category <- NULL
        
        sku2 <- data.frame(lapply(sku2, function(v) {
          if (is.character(v)) return(tolower(v))
          else return(v)
        }))
        
        sku1 <- data.frame(lapply(sku1, function(v) {
          if (is.character(v)) return(tolower(v))
          else return(v)
        }))
        
        #sku1Tar <- sku2
        
        
        sku1Tar <- data.frame(Brand = sku2$Brand, Variant=sku2$VARIANTA,  Form=sku2$FORM, Package=sku2$PACKAGE, SKU.Name=sku2$Long.Description, Packsize=sku2$Packsize)
        
        sku1Tar$descrp <- paste(sku1Tar$Form, sku1Tar$Brand, sku1Tar$Variant, sku1Tar$Package, sku1Tar$Packsize, sep = " ")
        sku1$descrp <- paste(sku1$Form, sku1$Brand, sku1$Variant, sku1$Package, sku1$Packsize, sep = " ")
        
        sku1$Packsize <- str_replace_all(sku1$Packsize, fixed(" "), "")
        sku1Tar$Packsize <- str_replace_all(sku1Tar$Packsize, fixed(" "), "")
        
        
        
        # ---------- record linkage package ops ----------------------- 
        
        #  unique(sku1$Packsize) 
        #  unique(sku2$Packsize) 
        #  
        #  unique(sku1$Package)
        #  unique(sku2$PACKAGE)
        
        
        #--------- stochastic prediction + blocking -------------
        rpairs <- compare.linkage(sku1, sku1Tar, blockfld = c(1,2,3,4,6),
                                  phonetic = FALSE, phonfun = pho_h, 
                                  strcmp = FALSE, strcmpfun = jarowinkler, 
                                  exclude = c(5)
        )
        
        rpairsBlock <- rpairs
        rpBlkPairs <- rpairs$pairs
        
        finalPairs <- rpairs$pairs[, c("id1", "id2")]
        
        
        #----------- brute force linkage + unsupervised prediction ---------
        rpairs <- compare.linkage(sku1, sku1Tar, exclude = c(5))
        
        unsupMethod <- 'kmeans'
        unsup.methods<-input$show_algos
        unsupMethod <- unsup.methods[1]
        
        #rpairsUnsup <- classifyUnsup(rpairs, method = "kmeans")
        rpairsUnsup <- classifyUnsup(rpairs, method = unsupMethod)
        
        summary(rpairsUnsup)
        rpUnsupPairs <- rpairsUnsup$pairs[ rpairsUnsup$prediction == 'L', ]
        
        
        # ---- get all pairs that are not predicted in stochastic but in kmeans ------------------
        rpFocusParis <- rpUnsupPairs[-which(rpUnsupPairs$id1 %in% rpBlkPairs$id1), ]
        
        #unique(rpFocusParis$id1)
        #unique(rpBlkPairs$id1)
        #head(rpFocusParis)
        
        #--------- get their field to field distance proximity summation ---------------
        rpFocusParis$colsum <- rowSums(rpFocusParis[, c(3:8)], na.rm = TRUE)
        rpFocusParis <- rpFocusParis[with(rpFocusParis, order(id1, id2, -colsum)), ]
        
        head(rpFocusParis[with(rpFocusParis, order(-colsum, id1, id2)), ], 20)
        probRecs <- sqldf("Select id1, colsum, count(*) as counter from rpFocusParis group by id1, colsum order by id1, colsum DESC")
        
        
        #---- settle those with more than 4 field matching ones ----------------------
        probRun <- probRecs[probRecs$colsum == 4,] 
        probRun$id2 <- 0
        rownames(probRun) <- seq(length=nrow(probRun))
        
        for (q in 1:nrow(probRun)) {
          id1q <- probRun[q,"id1"]
          
          srcTest <- sku1[id1q,]
          tarTest <- sku1Tar[
            rpFocusParis[rpFocusParis$id1==id1q & rpFocusParis$colsum==4,"id2"], ]
          
          res <- getMatchingId(srcTest, tarTest)
          if (!is.null(res)){
            probRun[q,"id2"] <- as.numeric(rownames(res))  
          }
          
        }
        
        finalPairs <- rbind(finalPairs, probRun[,c("id1", "id2")])
        
        #---- settle those with more than 3 field matching ones ----------------------
        probRun <- probRecs[probRecs$colsum == 3,] 
        probRun <- probRun[-which(probRun$id1 %in% finalPairs$id1),]
        
        probRun$id2 <- 0
        rownames(probRun) <- seq(length=nrow(probRun))
        
        for (q in 1:nrow(probRun)) {
          id1q <- probRun[q,"id1"]
          
          srcTest <- sku1[id1q,]
          tarTest <- sku1Tar[
            rpFocusParis[rpFocusParis$id1==id1q & rpFocusParis$colsum==3,"id2"], ]
          
          res <- getMatchingId(srcTest, tarTest)
          if (!is.null(res)){
            probRun[q,"id2"] <- as.numeric(rownames(res))  
          }
        }
        
        finalPairs <- rbind(finalPairs, probRun[,c("id1", "id2")])
        
        finalPairs <- finalPairs[with(finalPairs, order(id1, id2)), ]
        
        #------ reload all data for Accuracy caluculation -------------------
        skuSrc <- read.csv(source.file, header=TRUE, sep="\t", stringsAsFactors = FALSE)
        skuTar <- read.csv(source.file2, header=TRUE, sep="\t", stringsAsFactors = FALSE)
        comprSku1 <- read.csv(compr.file, header=TRUE, sep="\t", stringsAsFactors = FALSE)
        
        #skuSrc <-read.csv('D:/Data Mining/05-Unilever2/Uni-Inputs/Sku-Int-DataSet1.csv',header = TRUE, sep = ",", stringsAsFactors = FALSE)
        #skuTar <-read.csv('D:/Data Mining/05-Unilever2/Uni-Inputs/Sku-Ext-DataSet2.csv',header = TRUE, sep = ",", stringsAsFactors = FALSE)
        #comprSku1 <- read.csv('D:/Data Mining/05-Unilever2/Uni-Inputs/SKU_Match.txt',header = TRUE, sep = "\t", stringsAsFactors = FALSE)
        
        
        #------------------- remove period in colnames -------------------------
        colnames(skuTar) <- paste("Ext", colnames(skuTar), sep = "_")
        colnames(skuSrc) <- gsub("[.]", "", colnames(skuSrc))
        colnames(skuTar) <- gsub("[.]", "", colnames(skuTar))
        colnames(comprSku1) <- gsub("[.]", "", colnames(comprSku1))
        
        #-------reorder rownames ------------------------------
        skuSrc$id1 <- seq(length=nrow(skuSrc))
        skuTar$id2 <- seq(length=nrow(skuTar))
        
        skuMatch <- sqldf("Select distinct s.*, t.* from finalPairs f, skuSrc s, skuTar t where f.id1 = s.id1 and f.id2 = t.id2")
        comprSku1$id1 <- 0
        comprSku1$id2 <- 0
        
        #---------------- find id1 for matched set of 10 rec from source sku --------------------
        for (k in 1:nrow(comprSku1)){
          currRec <- comprSku1[k,]
          vf <- sqldf("Select s.id1 from currRec c, skuSrc s where 
                      c.Category=s.Category and c.Brand=s.Brand and c.Variant=s.Variant and   
                      c.Form=s.Form and c.Package=s.Package and c.Size=s.Size and         
                      c.SKUName=s.SKUName and c.Packsize=s.Packsize")
          comprSku1[k, "id1"] <- vf$id1
        }
        
        #---------------- find id2 for matched set of 10 rec from target sku --------------------
        for (k in 1:nrow(comprSku1)){
          currRec <- comprSku1[k,]
          #print(currRec)
          vf <- sqldf("Select s.id2 from currRec c, skuTar s where 
              c.Ext_FORM=s.Ext_FORM and                      
              c.Ext_SUBSEGMENT=s.Ext_SUBSEGMENT and          
              c.Ext_Brand=s.Ext_Brand and                    
              c.Ext_VARIANTA=s.Ext_VARIANTA and
              c.Ext_PACKAGE=s.Ext_PACKAGE and                
              c.Ext_Packsize=s.Ext_Packsize and
              c.Ext_LongDescription=s.Ext_LongDescription")
          if (nrow(vf) > 0) {
            comprSku1[k, "id2"] <- vf$id2  
          }
          
        }
        
        truth <- comprSku1[,c("id1", "id2")]
        pred <- finalPairs[finalPairs$id1 %in% comprSku1$id1 ,c("id1", "id2")]
        colnames(pred)[2] <- "id2Pred"
        mtrx <- merge(x = truth, y = pred, by = "id1", all.x = TRUE)
        mtrx$truth <- ifelse(mtrx$id2 > 0,1,0)
        mtrx$pred <- ifelse(mtrx$id2 == mtrx$id2Pred, mtrx$truth, !mtrx$truth)
        mtrx[is.na(mtrx$pred), "pred"] <- 0
        levels(mtrx$truth) <- c(0, 1)
        levels(mtrx$pred) <- c(0, 1)
        mtrx$truthvspred <- ifelse(mtrx$truth == mtrx$pred, 1, 0)
        
        cfm <- confusionMatrix(mtrx$truth, mtrx$pred)  
        #vals$confMatrix <- fourfoldplot(cfm$table, color = c("#CC6666", "#99CC99"), conf.level = 0, margin = 1, main = "Confusion Matrix")
        vals$confMatrix <- cfm$table
        
        text1 <- paste(names(cfm$overall), '=', cfm$overall, collapse=', ')
        text2 <- paste(names(cfm$byClass), '=', cfm$byClass, collapse=', ')
        
        vals$confusionMatrixUI <- paste('--Overall : ',text1,'--byClass : ',text2,sep = "\r\n")
        
        
        vals$comprMatched <- mtrx
        
        #------------------ end processing -------------------------------
        vals$matchMsg = paste('Accuracy calibrated with given matched records : ', cfm$overall["Accuracy"], sep="")
        
        vals$matchedDS <- skuMatch
        write.table(skuMatch, sep="\t",  file=matched.file, row.names=FALSE, quote=FALSE)
        #write.table(compData, sep="\t",  file="compData1.txt", row.names=FALSE, quote=FALSE)         
        
        #print(comprSku1)        
        vals$comparedOnes <- comprSku1
        write.table(comprSku1, sep="\t",  file=matchedCompr.file, row.names=FALSE, quote=FALSE)         
        
        
        vals$statusMsg <- paste('Written Matched Records to :',matched.file, 'and comparision against given subset of matched records to', matchedCompr.file, sep=" " )
      
      }
      
      
    })
  })
  
  
  
  

  
  
})