#Title: Decay rate infor
#Auther: Naoto Imamachi
#ver: 1.0.0
#Date: 2015-10-09

###Decay_rate_Infor_function###
BridgeRHalfLifeComparison <- function(filename = "BridgeR_5C_HalfLife_calculation_R2_selection.txt", 
                                      group, 
                                      hour, 
                                      ComparisonFile, 
                                      InforColumn = 4, 
                                      LogScale=F, 
                                      Calibration=F, 
                                      OutputFig = "BridgeR_7_HalfLife_Comparison_ScatteredPlot",
                                      ModelMode = "R2_selection"){
    #ComparisonFile: The length of vector must be 2 => c("Control","Knockdown")
    ###Prepare_file_infor###
    time_points <- length(hour)
    group_number <- length(group)
    comp_file_number <- NULL
    for(a in 1:length(ComparisonFile)){
        comp_file_number <- append(comp_file_number, which(group == ComparisonFile[a]))
    }
    
    input_file <- fread(filename, header=T)
    figfile <- paste(OutputFig,"_",group[comp_file_number[1]],"_vs_",group[comp_file_number[2]],".png", sep="")
    png(filename=figfile,width = 1200, height = 1200)
    
    ###Plot_Half-life_comparison###
    half_life_column_1 <- NULL
    half_life_column_2 <- NULL
    if(ModelMode == "Three_model"){
        half_life_column_1 <- comp_file_number[1]*(time_points + InforColumn + 23) #number
        half_life_column_2 <- comp_file_number[2]*(time_points + InforColumn + 23) #number
    }else if(ModelMode == "Raw_model" || ModelMode == "R2_selection"){
        half_life_column_1 <- 1*(time_points + InforColumn) + 8 #number
        half_life_column_2 <- 2*(time_points + InforColumn) + 13 + 8 #number
    }
    
    half_1 <- as.numeric(input_file[[half_life_column_1]])
    half_2 <- as.numeric(input_file[[half_life_column_2]])
    half_data <- data.table(half1=half_1,half2=half_2)
    
    if(Calibration == T){
        test <- lm(half2 ~ half1 + 0, data=half_data)
        coef <- as.numeric(test$coefficients)
        half_2 <- half_2/coef
        
        half_2_r <- NULL
        for(x in half_2){
            if(is.na(x)){
            }else if(x >= 24){
                x <- 24
            }
            half_2_r <- append(half_2_r,x)
        }
        half_2 <- half_2_r
    }

    gene_number <- length(half_1)
    half_1_fig <- NULL
    half_2_fig <- NULL
    factor_fig <- NULL
    for(x in 1:gene_number){
        Pvalue <- NULL
        div <- NULL
        if(ModelMode == "Raw_model" || ModelMode == "R2_selection"){
            Pvalue_index <- (time_points + InforColumn + 13)*2 + 2
            div_index <- (time_points + InforColumn + 13)*2 + 1
            Pvalue <- as.numeric(as.vector(as.matrix(input_file[x, Pvalue_index, with=F])))
            div <- as.numeric(as.vector(as.matrix(input_file[x, div_index, with=F])))
            if(is.na(half_1[x]) || is.na(half_2[x]) || is.nan(Pvalue)){
                next
            }
        }else if(ModelMode == "Three_model"){
            if(is.na(half_1[x]) || is.na(half_2[x])){
                next
            }
        }
        
        
        half_1_fig <- append(half_1_fig, half_1[x])
        half_2_fig <- append(half_2_fig, half_2[x])
        div <- half_2[x]/half_1[x] # KD/Control
        if(ModelMode == "Three_model"){
            if(div <= 0.5){
                factor_fig <- append(factor_fig, 2)
            }else if(div >= 2){
                factor_fig <- append(factor_fig, 1)
            }else{
                factor_fig <- append(factor_fig, 0)
            }
        }else if(ModelMode == "Raw_model" || ModelMode == "R2_selection"){
            if(div <= 0.5 && Pvalue < 0.05){
                factor_fig <- append(factor_fig, 2)
            }else if(div >= 2 && Pvalue < 0.05){
                factor_fig <- append(factor_fig, 1)
            }else{
                factor_fig <- append(factor_fig, 0)
            }
        }
        
    }
    if(LogScale){
        half_1_fig <- log2(half_1_fig)
        half_2_fig <- log2(half_2_fig)
    }
    up_genes <- length(which(factor_fig == 1))
    down_genes <- length(which(factor_fig == 2))
    
    plot_data <- data.frame(half_1_fig,half_2_fig,factor_fig)
    print_out <- paste("Plotted: ",length(plot_data[,1])," genes", sep="")
    print_out2 <- paste("At least 2-fold upregulated: ",up_genes," genes", sep="")
    print_out3 <- paste("At least 2-fold downregulated: ",down_genes," genes", sep="")
    print(print_out)
    print(print_out2)
    print(print_out3)
    
    p.scatter <- ggplot()
    p.scatter <- p.scatter + geom_point(data=plot_data, 
                                   mapping=aes(x=half_1_fig, y=half_2_fig,colour=factor(factor_fig)), 
                                   #colour="black",
                                   size=2.5,
                                   alpha=0.3)
    
    p.scatter <- p.scatter + geom_smooth(data=plot_data, 
                                   mapping=aes(x=half_1_fig, y=half_2_fig),
                                   geom_params=list(color = "blue", size=1.2),
                                   stat="smooth",
                                   stat_params=list(method="lm", se=F))
    
    p.scatter <- p.scatter + xlim(0,max(plot_data$half_1_fig)) + ylim(0,max(plot_data$half_2_fig))
    p.scatter <- p.scatter + ggtitle("Half-life comparison")
    name_xlab <- paste(group[comp_file_number[1]]," (Time)", sep="")
    name_ylab <- paste(group[comp_file_number[2]]," (Time)", sep="")
    p.scatter <- p.scatter + xlab(name_xlab)
    p.scatter <- p.scatter + ylab(name_ylab)
    p.scatter <- p.scatter + theme(legend.position="none") #Remove Guides
    p.scatter <- p.scatter + scale_colour_manual(values=c("black","red","blue")) #Change color
    plot(p.scatter)
        
    dev.off() #close_fig
    plot.new()
}

BridgeRHalfLifeDistribution <- function(filename = "BridgeR_5C_HalfLife_calculation_R2_selection.txt", 
                                        group, 
                                        hour, 
                                        ComparisonFile, 
                                        InforColumn = 4, 
                                        OutputFig = "BridgeR_7_HalfLife_Distribution_LineGraph",
                                        ModelMode = "R2_selection"){
    ###Prepare_file_infor###
    time_points <- length(hour)
    group_number <- length(group)
    sample_number <- length(ComparisonFile)
    comp_file_number <- NULL
    figfile <- OutputFig
    for(a in 1:sample_number){
        comp_file_number <- append(comp_file_number, which(group == ComparisonFile[a]))
        figfile <- paste(figfile,"_",ComparisonFile[a], sep="")
    }
    figfile <- paste(figfile,".png", sep="")
    
    input_file <- fread(filename, header=T)
    png(filename=figfile,width = 1200, height = 1200)
    
    ###Plot_Half-life_distribution###
    half_life_fig <- NULL
    for(x in 1:sample_number){
    #for(x in 1){
        data_file <- NULL
        half_life_column <- NULL
        if(ModelMode == "Three_model"){
            half_life_column <- comp_file_number[x]*(time_points + InforColumn + 23) #number
        }else if(ModelMode == "Raw_model" || ModelMode == "R2_selection"){
            half_life_column <- (comp_file_number[x]-1)*(time_points + InforColumn + 13) + time_points + InforColumn + 8 #number
        }
        half_life_data <- input_file[[half_life_column]]
        half_life_data <- half_life_data[!is.na(half_life_data)]
        if(x == 1){
            Sample <-  as.factor(rep(ComparisonFile[x], length(half_life_data)))
            half_life_fig <- data.frame(half_life_data, Sample)
        }else{
            Sample <-  as.factor(rep(ComparisonFile[x], length(half_life_data)))
            half_life_fig <- rbind(half_life_fig, data.frame(half_life_data, Sample))
        }
    }

    p.scatter <- ggplot()
    p.scatter <- p.scatter + geom_freqpoly(data=half_life_fig, 
                                   mapping=aes(x=half_life_data, colour=Sample), 
                                   binwidth=0.1,
                                   #geom="line",
                                   #stat="density",
                                   size=1.2,
                                   alpha=0.5)
    p.scatter <- p.scatter + xlim(0,25)
    p.scatter <- p.scatter + ggtitle("Half-life distribution")
    p.scatter <- p.scatter + xlab("half-life")
    p.scatter <- p.scatter + ylab("Transcripts #")
    #library(scales)
    #p.scatter <- p.scatter + scale_y_continuous(labels = percent)
    plot(p.scatter)
    
    dev.off() #close_fig
    plot.new()
}

BridgeRHalfLifeDifferenceHist <- function(filename = "BridgeR_5C_HalfLife_calculation_R2_selection.txt", 
                                          group, 
                                          hour, 
                                          ComparisonFile, 
                                          InforColumn = 4, 
                                          BinwidthFig = 0.01, 
                                          Calibration = F, 
                                          OutputFig = "BridgeR_7_HalfLife_Difference_LineGraph",
                                          ModelMode = "R2_selection"){
    #ComparisonFile: The length of vector must be 2 => c("Control","Knockdown")
    ###Prepare_file_infor###
    time_points <- length(hour)
    group_number <- length(group)
    comp_file_number <- NULL
    for(a in 1:length(ComparisonFile)){
        comp_file_number <- append(comp_file_number, which(group == ComparisonFile[a]))
    }
    
    input_file <- fread(filename, header=T)
    figfile <- paste(OutputFig,"_",group[comp_file_number[1]],"_vs_",group[comp_file_number[2]],".png", sep="")
    png(filename=figfile,width = 1200, height = 1200)
    
    ###Plot_Half-life_comparison###
    half_life_column_1 <- NULL
    half_life_column_2 <- NULL
    if(ModelMode == "Three_model"){
        half_life_column_1 <- comp_file_number[1]*(time_points + InforColumn + 23) #number
        half_life_column_2 <- comp_file_number[2]*(time_points + InforColumn + 23) #number
    }else if(ModelMode == "Raw_model" || ModelMode == "R2_selection"){
        half_life_column_1 <- 1*(time_points + InforColumn) + 8 #number
        half_life_column_2 <- 2*(time_points + InforColumn) + 13 + 8 #number
    }

    half_1 <- as.numeric(input_file[[half_life_column_1]])
    half_2 <- as.numeric(input_file[[half_life_column_2]])
    half_2_r <- NULL
    for(x in half_2){
        if(is.na(x)){
        }else if(x >= 24){
            x <- 24
        }
        half_2_r <- append(half_2_r,x)
    }
    half_2 <- half_2_r
    half_data <- data.table(half1=half_1,half2=half_2)
    
    if(Calibration == T){
        test <- lm(half2 ~ half1 + 0, data=half_data)
        coef <- as.numeric(test$coefficients)
        half_2 <- half_2/coef
        
        half_2_r <- NULL
        for(x in half_2){
            if(is.na(x)){
            }else if(x >= 24){
                x <- 24
            }
            half_2_r <- append(half_2_r,x)
        }
        half_2 <- half_2_r
    }
    
    div_half <- log2(half_2/half_1)
    
    print(summary(half_1))
    print(summary(half_2))

    plot_data <- data.frame(div_half)

    p.scatter <- ggplot()
    p.scatter <- p.scatter + geom_freqpoly(data=plot_data, 
                                   mapping=aes(x=div_half), 
                                   binwidth=BinwidthFig,
                                   #geom="line",
                                   #stat="density",
                                   size=1.2)
    p.scatter <- p.scatter + xlim(min(plot_data$div_half),max(plot_data$div_half))
    p.scatter <- p.scatter + ggtitle("Half-life difference")
    name_xlab <- paste("Relative half-life(",group[comp_file_number[1]],"_vs_",group[comp_file_number[2]],")",sep="")
    p.scatter <- p.scatter + xlab(name_xlab)
    p.scatter <- p.scatter + ylab("Transcripts #")
    plot(p.scatter)
    
    dev.off() #close_fig
    plot.new()
}

BridgeRHalfLifeDifferenceBox <- function(filename = "BridgeR_5C_HalfLife_calculation_R2_selection.txt", 
                                         group, 
                                         hour, 
                                         ComparisonFile, 
                                         InforColumn = 4, 
                                         Calibration = F, 
                                         OutputFig = "BridgeR_7_HalfLife_Comparison_BoxPlot",
                                         ModelMode = "R2_selection"){
    #ComparisonFile: The length of vector must be 2 => c("Control","Knockdown")
    ###Prepare_file_infor###
    time_points <- length(hour)
    group_number <- length(group)
    comp_file_number <- NULL
    for(a in 1:length(ComparisonFile)){
        comp_file_number <- append(comp_file_number, which(group == ComparisonFile[a]))
    }
    
    input_file <- fread(filename, header=T)
    figfile <- paste(OutputFig,"_",group[comp_file_number[1]],"_vs_",group[comp_file_number[2]],".png", sep="")
    fig_width <- 200*length(ComparisonFile)
    png(filename=figfile,width = fig_width, height = 1200)
    
    ###Plot_Half-life_comparison###
    half_life_column_1 <- NULL
    half_life_column_2 <- NULL
    if(ModelMode == "Three_model"){
        half_life_column_1 <- comp_file_number[1]*(time_points + InforColumn + 23) #number
        half_life_column_2 <- comp_file_number[2]*(time_points + InforColumn + 23) #number
    }else if(ModelMode == "Raw_model" || ModelMode == "R2_selection"){
        half_life_column_1 <- 1*(time_points + InforColumn) + 8 #number
        half_life_column_2 <- 2*(time_points + InforColumn) + 13 + 8 #number
    }
    
    half_1 <- as.numeric(input_file[[half_life_column_1]])
    half_2 <- as.numeric(input_file[[half_life_column_2]])
    half_2_r <- NULL
    for(x in half_2){
        if(is.na(x)){
        }else if(x >= 24){
            x <- 24
        }
        half_2_r <- append(half_2_r,x)
    }
    half_2 <- half_2_r
    half_data <- data.table(half1=half_1,half2=half_2)
    
    if(Calibration == T){
        test <- lm(half2 ~ half1 + 0, data=half_data)
        coef <- as.numeric(test$coefficients)
        half_2 <- half_2/coef
        
        half_2_r <- NULL
        for(x in half_2){
            if(is.na(x)){
            }else if(x >= 24){
                x <- 24
            }
            half_2_r <- append(half_2_r,x)
        }
        half_2 <- half_2_r
    }
    
    half_1 <- half_1[!is.na(half_1)]
    half_1_number <- length(half_1)
    half_1_label <- rep(ComparisonFile[1],half_1_number)
    plot_data_1 <- data.frame(half_1,half_1_label)
    colnames(plot_data_1) <- c("half_data","label")
    
    half_2 <- half_2[!is.na(half_2)]
    half_2_number <- length(half_2)
    half_2_label <- rep(ComparisonFile[2],half_2_number)
    plot_data_2 <- data.frame(half_2,half_2_label)
    colnames(plot_data_2) <- c("half_data","label")
    
    print(summary(half_1))
    print(summary(half_2))
    
    plot_data <- rbind(plot_data_1,plot_data_2)

    p.boxplot <- ggplot()
    p.boxplot <- p.boxplot + geom_boxplot(data=plot_data, 
                                   mapping=aes(x=label, y=half_data))
    p.boxplot <- p.boxplot + ylim(0,24)
    p.boxplot <- p.boxplot + ggtitle("Half-life difference")
    p.boxplot <- p.boxplot + ylab("Half-life")
    plot(p.boxplot)
    
    dev.off() #close_fig
    plot.new()
}
