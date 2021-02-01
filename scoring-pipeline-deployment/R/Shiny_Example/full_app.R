
library(shiny)
library(shinythemes)
library(ggplot2)
library(daimojo) #mojo.load is done from the pre processing R file
library(DT)
library(reshape2)
library(dplyr)
library(caret)
library(data.table)

#############################################################################################
##########                         Data Prep for Shiny App                        ###########
#############################################################################################
setwd("/Users/felix/Code/h2oai/driverlessai-tutorials/scoring-pipeline-deployment/R/Shiny_Example")
train_dataset <- read.csv("CreditCardRe_Train.csv") #train_dataset
dataset <- train_dataset
colnames(train_dataset)

int_cols <- c("LIMIT_BAL", "BILL_AMT1", "BILL_AMT2", "BILL_AMT3", "BILL_AMT4", "BILL_AMT5", "BILL_AMT6", "PAY_AMT1", "PAY_AMT2", "PAY_AMT3", "PAY_AMT4", "PAY_AMT5", "PAY_AMT6")
cat_cols <- c("SEX", "EDUCATION", "MARRIAGE")
numeric_cat_cols <- c("AGE", "PAY_0", "PAY_2", "PAY_3", "PAY_4", "PAY_5", "PAY_6")
target <- 'default.payment.next.month'
predictor_colnames <- colnames(train_dataset)[colnames(train_dataset) != target]

predictions_df <- read.csv("train_preds.csv", header = TRUE)
colnames(predictions_df)[2] <- "prob_pred"
nrow(predictions_df)
nrow(train_dataset)

dataset_w_pred <- cbind(train_dataset, predictions_df)
colnames(dataset_w_pred)[colnames(dataset_w_pred) == 'default.payment.next.month'] <- "Actual_Target"
Sys.setenv("DRIVERLESS_AI_LICENSE_KEY" = "paste_your_key_here")
model = daimojo::load.mojo("mojo-pipeline/pipeline.mojo")
col_class <- setNames(daimojo::feature.types(model), daimojo::feature.names(model))
new_data_dt <- fread("./mojo-pipeline/example.csv", colClasses=col_class, header=TRUE, sep=",")
new_data_dt <- new_data_dt[1, ]
mojo_predictor_colnames = colnames(new_data_dt)

##########################################################################
#####                        SHINY APP                               #####
##########################################################################

ui <- fluidPage(
  
  navbarPage(title = "DAI Dashboard", theme = shinytheme(theme = "cosmo"), windowTitle = "DAI and Shiny Integrations",
             
             tabPanel("Model Experiment Diagnostics",
                      
                      tabsetPanel(id = "within_diagnostics",
                                  tabPanel("Distribution",
                                           fluidRow(
                                             column(width = 12, h2("Prediction Probability Distirbution"))
                                           ),
                                           
                                           fluidRow(
                                             column(width = 12, plotOutput("op_train_pred_prob_dist"))
                                           )
                                  ),
                                  
                                  tabPanel("Performance Metrics",
                                           
                                           fluidRow(
                                             h2()
                                           ),
                                           
                                           fluidRow(
                                             h2()
                                           ),
                                           
                                           fluidRow(
                                             column(width = 4, offset=2, align = "right", h3("Class Threshold Cutoff")),
                                             column(width = 6, sliderInput(inputId = "ip_threshold_cutoff", label = NULL , min = 0, max = 1, value = 0.5, step = 0.05, animate = TRUE))
                                           ),
                                           
                                           hr(),
                                           
                                           fluidRow(
                                             column(width = 6, offset = 3, dataTableOutput("op_confusion_matrix_train") )
                                           ),
                                           
                                           hr(),
                                           
                                           
                                           #fluidRow(h1()),
                                           
                                           #fluidRow(h1()),
                                           
                                           #fluidRow(h1()),
                                           
                                           #fluidRow(h1()),
                                           
                                           fluidRow(
                                             column(width = 2, offset = 3, align = "center", h1("Precision", style="color:green;")),
                                             column(width = 2, offset = 2, align = "center", h1("Recall", style="color:green;"))
                                           ),
                                           
                                           fluidRow(
                                             column(width = 2, offset = 3, align = "center", h1(strong(textOutput("op_precision_train")), style="font-size:40px;")),
                                             column(width = 2, offset = 2, align = "center", h1(strong(textOutput("op_recall_train")), style="font-size:40px;"))
                                           ),
                                           
                                           hr(),
                                           
                                           fluidRow(
                                             column(width = 6, offset = 3, align = "center", h1("ACCURACY", style="color:green"))
                                           ),
                                           
                                           fluidRow(
                                             column(width = 6, offset = 3, align = "center", h1(strong(textOutput("op_accuracy_train")), style="font-size:40px;"))
                                           ),
                                           
                                           hr(),
                                           
                                           fluidRow(
                                             column(width = 2, offset = 3, align = "center", h1("F1", style="color:green")),
                                             column(width = 2, offset = 2, align = "center", h1("F0.5", style = "color:green"))
                                           ),
                                           
                                           fluidRow(
                                             column(width = 2, offset = 3, align = "center", h1(strong(textOutput("op_f1_train")), style="font-size:40px;")),
                                             column(width = 2, offset = 2, align = "center", h1(strong(textOutput("op_f0.5_train")), style="font-size:40px;"))
                                           )
                                           
                                           
                                           # fluidRow(   
                                           #    column(width = 2, offset = 1, align = "right", h1("Recall")),
                                           #    column(width = 2, h1(verbatimTextOutput("op_recall_train")))
                                           #    
                                           #  )
                                  )
                                  
                      )
             ),
             
             tabPanel("Business Simulations",
                      
                      tabsetPanel(id = "within_business",
                                  
                                  tabPanel("Data Upload",
                                           
                                           fluidRow(
                                             h2()
                                           ),
                                           
                                           fluidRow(
                                             column(width = 4, offset = 4, align = "center", fileInput(inputId = "ip_test_data_file",buttonLabel = "Upload", width = 500, label =  "Choose Test Data - CSV File",
                                                                                                       
                                                                                                       accept = c(
                                                                                                         "text/csv",
                                                                                                         "text/comma-separated-values,text/plain",
                                                                                                         ".csv")
                                             )
                                             )
                                           ),
                                           
                                           fluidRow(
                                             column(width = 12, DT::DTOutput("op_show_test_dataset") )
                                           ),
                                           
                                           fluidRow(
                                             column(width = 4, offset = 4, align = "center", actionButton(inputId = "bt_assign_intervention", label = "Assign Intervention Intensity"))
                                           )
                                  ),
                                  
                                  tabPanel("Intervention Assignment",
                                           
                                           fluidRow(
                                             
                                             column(width = 12, DT::DTOutput("op_show_intervention_dataset"))
                                           )
                                           
                                  ),
                                  
                                  tabPanel("Scenario Planner",
                                           
                                           fluidRow(
                                             column(width = 4, offset = 4, align = "center", h2("Average $ of intervention"))
                                             #column(width = 4, align = "left", h2(sliderInput(inputId = "ip_intervention_cost", label = NULL, min = 500, max = 200000, value = 50000, step = 2000), ))
                                           ),
                                           
                                           fluidRow(
                                             #column(width = 3, align = "right", h2("Mild Intervention Cost ($)")),
                                             column(width = 6, align = "center", h2(sliderInput(inputId = "ip_mild_intervention_cost", label = h2("Mild Intervention Cost ($)"), min = 500, max = 20000, value = 1000, step = 100, width = 600) )),
                                             #column(width = 3, align = "right", h2("High Intervention Cost ($)")),
                                             column(width = 6, align = "center", h2(sliderInput(inputId = "ip_high_intervention_cost", label = h2("High Intervention Cost ($)"), min = 500, max = 20000, value = 15000, step = 100, width = 600) ))
                                             
                                           ),
                                           
                                           
                                           hr(),
                                           
                                           fluidRow(
                                             #column(width = 3, align = "right", h2("Mild Intervention Recovery")),
                                             column(width = 6, align = "center", sliderInput(inputId = "ip_mild_intervention_recovery", label = h2("Mild Intervention Recovery"), min = 0, max = 100, step = 5, value = c(20, 40), post = " %", dragRange = TRUE, width = 600)),
                                             #column(width = 3, align = "right", h2("High Intervention Recovery")),
                                             column(width = 6, align = "center", sliderInput(inputId = "ip_high_intervention_recovery", label = h2("High Intervention Recovery"), min = 0, max = 100, step = 5, value = c(70, 90), post = " %", dragRange = TRUE, width = 600))
                                           ),
                                           
                                           hr(),
                                           
                                           fluidRow(h1()),
                                           
                                           fluidRow(
                                             column(width = 12, align = "center", actionButton(inputId =  "bt_business_savings", label = "Estimate Potential Savings", width = 300)),
                                           ),
                                           
                                           fluidRow(h1()),
                                           
                                           fluidRow(h1()),
                                           
                                           fluidRow(
                                             column(width = 3, align = "center", h2("Total Cost", style="color:red")),
                                             column(width = 3, align = "center", h2(textOutput("op_show_total_cost"))),
                                             column(width = 3, align = "center", h2("Total Potential Recovery", style="color:green")),
                                             column(width = 3, align = "center", h2(textOutput("op_show_total_recovery")))
                                             # column(width = 3, align = "center", h1("Total Potential Savings", style="color:green")),
                                             # column(width = 3, align = "center", h1(textOutput("op_show_total_savings")))
                                           ),
                                           
                                           hr(),
                                           
                                           hr(),
                                           
                                           fluidRow(
                                              column(width = 6, align = "center", h1("Total Potential Savings", style="color:green")),
                                              column(width = 6, align = "left", h1(textOutput("op_show_total_savings")))
                                            )
                                           
                                  ),
                                  
                                  tabPanel("$ Savings",
                                           
                                           fluidRow(
                                             
                                             column(width = 12, DT::DTOutput("op_show_business_savings_dataset"))
                                           )
                                           
                                  ),
                                  
                                  tabPanel("Savings - Visuals",
                                           
                                           fluidRow(
                                             column(width = 6, align = "center", h2("Recovery Amount ($) Distribution")),
                                             column(width = 6, align = "center", h2("Net Savings ($) Distribution"))
                                             
                                           ),
                                           
                                           fluidRow(
                                             
                                             #column(width = 6, align = "center",  plotOutput("op_show_cost_distribution")),
                                             column(width = 6, align = "center",  plotOutput("op_show_recovery_distribution")),
                                             column(width = 6, align = "center",  plotOutput("op_show_savings_distribution"))
                                             
                                           ),
                                           
                                           fluidRow(
                                             
                                             
                                           )
                                           
                                  )
                      )
             ),
             
             tabPanel("Model Predictions",
                      
                      tabsetPanel(id = "within_Prediction",
                                  tabPanel("Single Prediction",
                                           
                                           fluidRow(
                                             
                                             column(width = 3, h3("Numeric Vars")),
                                             column(width = 3, h3("Categorical - numeric")),
                                             column(width = 3, h3("Categorical - text")),
                                             column(width = 3, align = "center",
                                                    fluidRow(h3("")),
                                                    # fluidRow(h3("")),
                                                    # fluidRow(h3("")),
                                                    # fluidRow(h3("")),
                                                    # fluidRow(h3("")),
                                                    actionButton(inputId = "bt_SinglePredict", label = "Predict", width = 200)
                                             )
                                           ),
                                           
                                           
                                           fluidRow(
                                             
                                             
                                             column(width = 3,
                                                    lapply(colnames(dataset[, int_cols]), function(i){
                                                      min_value <- min(dataset[, i])
                                                      max_value <- max(dataset[, i])
                                                      range <- max_value - min_value
                                                      mean_value <- mean(dataset[, i])
                                                      numericInput(inputId = paste0("ip_", i), label = i, min = min_value, max = max_value, value = round(mean_value,0), width = 300)
                                                    }),
                                             ),
                                             
                                             column(width = 3,
                                                    
                                                    lapply(colnames(dataset[, numeric_cat_cols]), function(i){
                                                      unique_values = unique(dataset[, i])
                                                      selectInput(inputId = paste0("ip_", i), label = i, choices = sort(unique_values), width = 300, selected = min(unique_values))
                                                    }),
                                             ),
                                             
                                             column(width = 3,
                                                    
                                                    lapply(colnames(dataset[, cat_cols]), function(i){
                                                      unique_values = unique(dataset[, i])
                                                      selectInput(inputId = paste0("ip_", i), label = i, choices = sort(unique_values), width = 300, selected = unique_values[1])
                                                    }),
                                                    
                                             )
                                           ),
                                           
                                           
                                           hr(),
                                           
                                           # fluidRow(
                                           #   column(width = 6, offset = 4,
                                           #          actionButton(inputId = "bt_Useless_Predict", label = "Predict", width = 500, style = 'font-size:80%' )
                                           #   )
                                           # ),
                                           
                                           fluidRow(h3("")),
                                           
                                           fluidRow(h3("")),
                                           
                                           fluidRow(h3("")),
                                           
                                  ),
                                  
                                  tabPanel("Single Prediction Result",
                                           
                                           
                                           fluidRow(
                                             column(width = 3, align = "right", h3("Probability of Default: ")),
                                             column(width = 3, align = "left", h3(textOutput("op_single_pred_text"))),
                                             column(width = 3, align = "right", h2("Expected Loss: ")),
                                             column(width = 3, align = "left", h2(textOutput("op_single_pred_expected_loss"), style = "color:red")),
                                           ),
                                           
                                           hr(),
                                           
                                           fluidRow(
                                             column(width = 12, align = "center", h3("Prediction Probability Distribution of training data"))
                                           ),
                                           
                                           fluidRow(
                                             column(width = 12, align = "center", plotOutput("op_pred_prob_dist"))
                                           ),
                                           
                                           hr(),
                                           
                                           fluidRow(
                                             column(width = 12, align = "center",  h3("Predictor Variable Distribution"))
                                           ),
                                           
                                           fluidRow( 
                                             column(width = 4, offset = 4, align = "center", selectizeInput(inputId = "ip_predictor", label = "Choose Predictor", choices = predictor_colnames, multiple = FALSE, selected = predictor_colnames[1],  width = "100%"))
                                           ),
                                           
                                           fluidRow(
                                             column(width = 12, align = "center", plotOutput("op_predictor_dist"))
                                           ),
                                           
                                           
                                           
                                           
                                  )
                      )
             ) # tabpanel single prediction
             
             
  )
  
  
)

server <- function(input, output, session){
  
  # uw_num_summary_fun <- reactive({
  #   cols_selected <- input$uw_num_cols
  #   df <- uw_claims_data
  # }
  # )
  
  output$op_train_pred_prob_dist <- renderPlot(
    ggplot(dataset_w_pred, aes(x = prob_pred, fill = Actual_Target)) + geom_histogram(bins = 100, color = "black") + theme_classic() + scale_x_continuous(breaks = seq(0,1,0.1), limits = c(0,1)) + theme(legend.text=element_text(size=20), legend.box = "horizontal", legend.key.size = unit(5, "line"))
  )
  
  fun_confusion_matrix_train_diagnostics <- reactive({
    dataset_w_pred$pred_class <- 0
    dataset_w_pred$pred_class <- ifelse(dataset_w_pred$prob_pred > input$ip_threshold_cutoff, '1_Default', '0_Non-Default')
    
    cm <- confusionMatrix(data = as.factor(dataset_w_pred$pred_class), reference = as.factor(dataset_w_pred$Actual_Target))
    cm_df <- as.data.frame(cm$table)
    cm_df_cast <- reshape2::dcast(cm_df, Prediction~Reference)
    colnames(cm_df_cast)[1] <- "Confusion Matrix - Prediction/Reference"
    return(cm_df_cast)
  }) 
  
  #output$op_confusion_matrix_train <- renderTable({fun_confusion_matrix_train_diagnostics()}, bordered = TRUE, align = 'c', width = '100%', spacing = 'l',  )  
  #https://gallery.shinyapps.io/109-render-table/?_ga=2.126546061.1831340015.1589553038-1114439810.1589553038
  
  output$op_confusion_matrix_train <- DT::renderDataTable(datatable(fun_confusion_matrix_train_diagnostics(),
                                                                    options = list(
                                                                      columnDefs = list(list(width = '20', targets = 1)),
                                                                      columnDefs = list(list(width = '40', target = c(2,3)))
                                                                      #
                                                                      #formatStyle('1', '0', backgroundColor = styleEqual(c(0,1), c('green', 'gray')))
                                                                    )
  ) %>% formatStyle('0', 'Confusion Matrix - Prediction/Reference', backgroundColor = styleEqual(c(0,1), c('Chartreuse', 'DarkSalmon')))
  %>% formatStyle('1', 'Confusion Matrix - Prediction/Reference', backgroundColor = styleEqual(c(0,1), c('DarkSalmon', 'Chartreuse')))
  )
  
  
  fun_scorer_metrics_train_diagnostics <- reactive({
    cm_df_cast <- fun_confusion_matrix_train_diagnostics()
    ##            Actuals  0    1
    ##Predictions       0  TN   FN
    #                   1  FP   TP
    
    TN <- cm_df_cast[1,2]
    TP <- cm_df_cast[2,3]
    FN <- cm_df_cast[1,3]
    FP <- cm_df_cast[2,2]
    
    Precision <- round(TP / (TP + FP), 2)
    Recall <- round(TP / (TP + FN),2)
    F1 <- round(2 * (Precision * Recall) / (Precision + Recall),2)
    F0.5 <- round(1+ (0.5*0.5) * (Precision * Recall) / ((0.5*0.5) * Precision + Recall),2)
    Accuracy <- round((TP + TN) / (TP + FP + TN + FN) * 100, 2)
    
    metric_list <- list(Precision, Recall, F1, F0.5, Accuracy)
    metric_list <- data.frame(metric_list)
    colnames(metric_list) <- c("Precision", "Recall", "F1", "F0.5", "Accuracy")
    return(metric_list)
  })
  
  
  output$op_precision_train <- renderText({
    metric_df <- fun_scorer_metrics_train_diagnostics()
    paste0(metric_df$Precision)
  })                                                
  
  
  output$op_recall_train <- renderText({
    metric_df <- fun_scorer_metrics_train_diagnostics()
    paste0(metric_df$Recall)
  }) 
  
  output$op_accuracy_train <- renderText({
    metric_df <- fun_scorer_metrics_train_diagnostics()
    paste0(metric_df$Accuracy, " %")
  })  
  
  output$op_f1_train <- renderText({
    metric_df <- fun_scorer_metrics_train_diagnostics()
    paste0(metric_df$F1)
  })  
  
  output$op_f0.5_train <- renderText({
    metric_df <- fun_scorer_metrics_train_diagnostics()
    paste0(metric_df$F0.5)
  }) 
  
  
  
  #####################         Business Simulations      ##########################
  
  
  stored_test_df <- reactiveValues(raw_test_data = NULL,
                                   test_data_w_intervention = NULL,
                                   business_savings_data = NULL) 
  
  fun_read_test_data <- reactive({
    infile <- input$ip_test_data_file
    print(infile)
    print("inside fun_read_test_data")
    if (is.null(infile)) {
      # User has not uploaded a file yet
      return(NULL)
    }
    test_data <- read.csv(infile$datapath)
    print("test_data_while_reading")
    #print(test_data)
    
    colnames(test_data)[colnames(test_data) == "default.payment.next.month"] <- "Actual_Class"
    # dont_show_cols <- c("PAY_AMT4", "PAY_AMT5", "PAY_AMT6", "PAY_4", "PAY_5", "PAY_6", "BILL_AMT4", "BILL_AMT5", "BILL_AMT6")
    # cols_to_show <- setdiff(colnames(test_data), dont_show_cols)
    # test_data <- test_data[, cols_to_show]
    
    stored_test_df$raw_test_data <- test_data
    print("stored")
    print(stored_test_df$raw_test_data)
    
    return(test_data)
  })
  
  fun_show_test_data <- reactive({
    fun_read_test_data()
    df_to_show <- stored_test_df$raw_test_data
    #print(paste0("inside fun_show_test_data", df_to_show))
    dont_show_cols <- c("PAY_AMT4", "PAY_AMT5", "PAY_AMT6", "PAY_4", "PAY_5", "PAY_6", "BILL_AMT4", "BILL_AMT5", "BILL_AMT6")
    cols_to_show <- setdiff(colnames(df_to_show), dont_show_cols)
    df_to_show <- df_to_show[, cols_to_show]
    return(df_to_show)
  })
  
  #https://yihui.shinyapps.io/DT-edit/
  output$op_show_test_dataset <- DT::renderDT(fun_show_test_data(),
                                              editable = TRUE, server = TRUE)
  
  
  
  observeEvent(input$bt_assign_intervention, {
    showModal(modalDialog(
      title = "Intervention",
      paste0("Intervention Effectiveness assigned sucessfully. Look at \"Effectiveness Intervention\" Tab for more details"),
      easyClose = TRUE,
      # footer = tagList(
      #   modalButton("Okay"),
      # ),
      footer = NULL,
      fade = TRUE
    ))
  })
  
  fun_intervention_assignment <- eventReactive(input$bt_assign_intervention, {
    test_data_df <- stored_test_df$raw_test_data
    #test_data_df$Intervention[test_data_df$Actual_Class == 0] <- "No Intervention Required"
    test_data_df$random_number <- 0
    #total_positive_class <- nrow(test_data_df[test_data_df$Actual_Class==1,])
    #print(total_positive_class)
    test_data_df$random_number <- sample(1:2, nrow(test_data_df), replace = TRUE)
    test_data_df$Intervention[test_data_df$random_number == 1] <- "High Intervention"
    test_data_df$Intervention[test_data_df$random_number == 2] <- "Mild Intervention"
    
    dont_show_cols <- c("PAY_AMT4", "PAY_AMT5", "PAY_AMT6", "PAY_4", "PAY_5", "PAY_6", "BILL_AMT4", "BILL_AMT5", "BILL_AMT6", "random_number")
    cols_to_show <- setdiff(colnames(test_data_df), dont_show_cols)
    df_to_show <- test_data_df[, cols_to_show]
    stored_test_df$test_data_w_intervention <- test_data_df
    
    return(df_to_show)
  }
  )
  
  
  
  output$op_show_intervention_dataset <- DT::renderDT(fun_intervention_assignment(),
                                                      editable = TRUE, server = TRUE, rownames = FALSE)
  
  
  fun_calculate_business_savings <- eventReactive(input$bt_business_savings, {
    df <- stored_test_df$test_data_w_intervention
    print("came inside fun_business_recovery")
    prediction_df <- daimojo::predict.mojo(model, df)
    colnames(prediction_df) <- c("pred_prob_0", "pred_prob_1")
    df <- cbind(df, prediction_df)
    
    high_intervention_count <- nrow(df[df$Intervention == "High Intervention", ])
    mild_intervention_count <- nrow(df[df$Intervention == "Mild Intervention", ])
    
    df$Cost[df$Intervention == "High Intervention"] <- input$ip_high_intervention_cost
    df$Cost[df$Intervention == "Mild Intervention"] <- input$ip_mild_intervention_cost
    
    df$recovery_rate[df$Intervention == "High Intervention"] <- sample(input$ip_high_intervention_recovery[1]:input$ip_high_intervention_recovery[2], high_intervention_count, replace = TRUE)
    df$recovery_rate[df$Intervention == "Mild Intervention"] <- sample(input$ip_mild_intervention_recovery[1]:input$ip_mild_intervention_recovery[2], mild_intervention_count, replace = TRUE)
    
    ## recovery_rate is in 100's
    
    df$Recovery_Amount <- 0
    df$Recovery_Amount[df$Actual_Class == 1] <- df$recovery_rate[df$Actual_Class == 1]/100 * df$pred_prob_1[df$Actual_Class == 1] * df$LIMIT_BAL[df$Actual_Class == 1]
    df$Net_Savings <- df$Recovery_Amount - df$Cost
    
    stored_test_df$business_savings_data <- df
    print(stored_test_df$business_savings_data)
    return(df)
  })
  
  observeEvent(input$bt_business_savings, {
    showModal(modalDialog(
      title = "Savings",
      paste0("Savings calculated sucessfully. Look at \"$ Savings\" Tab for more details"),
      easyClose = TRUE,
      # footer = tagList(
      #   modalButton("Okay"),
      # ),
      footer = NULL,
      fade = TRUE
    ))
  })
  
  fun_show_business_savings_data <- reactive({
    fun_calculate_business_savings()
    df <- stored_test_df$business_savings_data
    print(nrow(df))
    cols_to_show <- c("ID", "LIMIT_BAL", "Intervention", "Cost", "Recovery_Amount", "pred_prob_1", "Actual_Class", "Net_Savings")
    df <- df[, cols_to_show]
    return(df)
  })
  
  
  output$op_show_business_savings_dataset <- DT::renderDT(fun_show_business_savings_data(),
                                                          editable = FALSE, server = TRUE, rownames = FALSE)
  
  
  output$op_show_total_cost <- renderText({
    df <- stored_test_df$business_savings_data
    cost <- sum(df$Cost)
    paste0("$", format(round(cost,2), big.mark=","))
  }
  )
  
  output$op_show_total_recovery <- renderText({
    df <- stored_test_df$business_savings_data
    recovery_amt <- sum(df$Recovery_Amount)
    paste0("$", format(round(recovery_amt,2), big.mark=","))
  })
  
  output$op_show_total_savings <- renderText({
    df <- stored_test_df$business_savings_data
    savings_amt <- sum(df$Net_Savings)
    paste0("$", format(round(savings_amt,2), big.mark=","))
  })
  
  
  
  output$op_show_cost_distribution <- renderPlot({
    df <- stored_test_df$business_savings_data
    print(df$Cost)
    df$Cost <- as.numeric(df$Cost)
    ggplot(df, aes(x = Cost)) + geom_histogram(bins = 20) + theme_classic()
  })
  
  output$op_show_recovery_distribution <- renderPlot({
    ggplot(stored_test_df$business_savings_data, aes(x = Recovery_Amount)) + geom_histogram(bins = 20) + theme_classic() # + ggtitle("Recovery Amount ($) Distribution")
  })
  
  output$op_show_savings_distribution <- renderPlot({
    ggplot(stored_test_df$business_savings_data, aes(x = Net_Savings)) + geom_histogram(bins = 20) + theme_classic() # + ggtitle("Net Savings ($) Distribution")
  })
  
  
  
  
  
  
  #####################        SINGLE PREDICTION      ##########################
  
  observeEvent(input$bt_SinglePredict, {
    showModal(modalDialog(
      title = "Prediction",
      paste0("Prediction obtained sucessfully from MOJO. Look at \"Single Prediction Result\" Tab for more details"),
      easyClose = TRUE,
      footer = tagList(
        modalButton("Okay"),
      ),
      fade = TRUE
    ))
  })
  
  fun_single_pred_from_mojo <- eventReactive(input$bt_SinglePredict, {
    # sample row
    print(str(dataset_w_pred))
    single_row_df <- dataset_w_pred[1, ]
    for(i in colnames(single_row_df)){
      if(i %in% numeric_cat_cols | i %in% int_cols)
        single_row_df[, i] <- as.numeric(input[[paste0("ip_",i)]])
    }
    
    print(single_row_df)
    print(str(single_row_df))
    single_pred_df <- daimojo::predict.mojo(model, single_row_df)
    print(single_pred_df[1,2])
    return(single_pred_df[1,2]) #Prediction of positive class - 1 row only available
    
  }
  )
  
  output$op_single_pred_text <- renderText(paste0(round(fun_single_pred_from_mojo()*100,2), " %"))
  
  
  output$op_pred_prob_dist <- renderPlot(
    ggplot(dataset_w_pred, aes(x = prob_pred, fill = Actual_Target)) + geom_histogram(bins = 100, color = "black") + theme_classic() + geom_point(x = fun_single_pred_from_mojo(), y = 0, size = 6, color = "purple") + scale_x_continuous(breaks = seq(0,1,0.1), limits = c(0,1)) + theme(legend.text=element_text(size=20), legend.box = "horizontal", legend.key.size = unit(5, "line"))
  )
  
  output$op_single_pred_expected_loss <- renderText(paste0("$", format(round(fun_single_pred_from_mojo() * input$ip_LIMIT_BAL, 0), big.mark=",")))
  
  
  ### Predictor distirbution and point of the single observation
  
  
  
  output$op_predictor_dist <- renderPlot(
    ggplot(dataset_w_pred, aes_string(x = input$ip_predictor)) + geom_histogram(bins = 100, color = "black") + theme_classic() + geom_point(aes_string(x = input[[paste0("ip_", input$ip_predictor)]], y = 0), size = 6, color = "purple") #+ scale_x_continuous(breaks = seq(0,1,0.1), limits = c(0,1))
  )
  
  
  
  
  output$uw_num_summary <- renderPrint(
    {
      summary(uw_claims_data[ , input$uw_num_cols])
    }
  )
  
  output$uw_num_hist <- renderPlot(
    {
      ggplot(uw_claims_data_num_melt[uw_claims_data_num_melt$variable %in% input$uw_num_cols,], aes(x = value)) + geom_histogram(bins = 20) + facet_wrap(~variable, ncol = 2, scales = "free")
    }
  )
  
  output$uw_factor_summary <- renderPrint(
    {
      summary(uw_claims_data[ , input$uw_factor_cols])
    }
  )
  
  output$uw_date_summary <- renderPrint(
    {
      summary(uw_claims_data[ , input$uw_date_cols])
    }
  )
  
  output$uw_num_claim_plot <- renderPlot(
    ggplot(uw_data_num_melt[uw_data_num_melt$variable %in% input$uw_num_forTarget_cols], aes(x = claim_yes_no, y = value)) + geom_boxplot() + facet_wrap(~variable, scales = "free_y", ncol = 5 ) + theme_classic()
  )
  
  output$uw_factor_claim_plot <- renderPlot(
    ggplot(uw_data_factor_melt[uw_data_factor_melt$variable %in% input$uw_factor_forTarget_cols], aes(x = value, fill = claim_yes_no )) + geom_bar(position = "stack") + facet_wrap(~variable, scales = "free", ncol = 3 ) + theme_classic()
  )
  
  
  output$uw_factor_claim_plot_stacked_percent <- renderPlot(
    ggplot(uw_data_factor_melt[uw_data_factor_melt$variable %in%input$uw_factor_forTarget_cols], aes(x = value, fill = claim_yes_no )) + geom_bar(position = "fill") + facet_wrap(~variable, scales = "free", ncol = 3 ) + theme_classic()
  )
  
  output$uw_date_claim_plot <- renderPlot(
    ggplot(uw_data_date_melt[uw_data_date_melt$variable %in% input$uw_date_forTarget_cols & uw_data_date_melt$value > "2018-01-01"], aes(x = value, fill = claim_yes_no )) + geom_bar(position = "stack") + facet_wrap(~variable, scales = "free", ncol = 3 ) + theme_classic()
  )
  
  output$uw_date_claim_plot_stacked_percent <- renderPlot(
    ggplot(uw_data_date_melt[uw_data_date_melt$variable %in% input$uw_date_forTarget_cols & uw_data_date_melt$value > "2018-01-01"], aes(x = value, fill = claim_yes_no )) + geom_bar(position = "fill") + facet_wrap(~variable, scales = "free", ncol = 3 ) + theme_classic()
  )
  
  output$uw_num_grossLoss_plot <- renderPlot({
    print(paste0("from input : ", input$uw_num_forGrossLoss_cols))
    print(paste0("from dataframe : ", unique(uw_claims_data_num_melt$variable)))
    ggplot(uw_claims_data_num_melt[uw_claims_data_num_melt$variable %in% input$uw_num_forGrossLoss_cols,], aes(x = value, y = gross_loss)) + geom_point() + facet_wrap(~variable, scales = "free", ncol = 5 ) + theme_classic()
  }
  )
  
  output$uw_factor_grossLoss_plot <- renderPlot(
    ggplot(uw_claims_data_factor_melt[uw_claims_data_factor_melt$variable %in% input$uw_factor_forGrossLoss_cols,], aes(x = value, y = gross_loss )) + geom_boxplot() + facet_wrap(~variable, scales = "free_y", ncol = 3 ) + theme_classic()
  )
  
  # output$uw_factor_claim_plot_stacked_percent <- renderPlot(
  #   ggplot(uw_data_factor_melt[uw_data_factor_melt$variable == input$uw_factor_forTarget_cols], aes(x = value, fill = claim_yes_no )) + geom_bar(position = "fill") + facet_wrap(~variable, scales = "free", ncol = 3 ) + theme_classic()
  # )
  
  
}

shinyApp(ui = ui, server = server)




