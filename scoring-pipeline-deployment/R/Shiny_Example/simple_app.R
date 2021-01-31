
library(shiny)
library(shinythemes)
library(dplyr)
library(ggplot2)

#############################################################################################
##########                         Data Prep for Shiny App                        ###########
#############################################################################################
setwd("/Users/felix/Code/h2oai/driverlessai-tutorials/scoring-pipeline-deployment/R/Shiny_Example")
train_dataset <- read.csv("CreditCardRe_Train.csv") #train_dataset
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
Sys.setenv("DRIVERLESS_AI_LICENSE_KEY" = "paste your license here")
model = daimojo::load.mojo("mojo-pipeline/pipeline.mojo")
daimojo::feature.names(model)
daimojo::feature.types(model)



ui <- fluidPage(
  
  navbarPage(title = "DAI Dashboard", theme = shinytheme(theme = "united"), windowTitle = "DAI and Shiny Integrations",
             
             tabPanel("Model Predictions",
                      
                      tabsetPanel(id = "within_Prediction",
                                  tabPanel("Single Prediction",
                                           
                                           fluidRow(
                                             
                                             column(width = 3, h3("Numeric Vars")),
                                             column(width = 3, h3("Categorical - numeric")),
                                             column(width = 3, h3("Categorical - text")),
                                             column(width = 2, align = "center",
                                                    fluidRow(h3("")),
                                                    actionButton(inputId = "bt_SinglePredict", label = "Predict", width = 200),
                                                    h3("Probability of Default: ", textOutput("op_single_pred_text1"))
                                             )
                                             
                                           ),
                                           
                                           
                                           fluidRow(
                                             
                                             
                                             column(width = 3,
                                                    lapply(colnames(train_dataset[, int_cols]), function(i){
                                                      min_value <- min(train_dataset[, i])
                                                      max_value <- max(train_dataset[, i])
                                                      range <- max_value - min_value
                                                      mean_value <- mean(train_dataset[, i])
                                                      numericInput(inputId = paste0("ip_", i), label = i, min = min_value, max = max_value, value = round(mean_value,0), width = 300)
                                                    }),
                                             ),
                                             
                                             column(width = 3,
                                                    
                                                    lapply(colnames(train_dataset[, numeric_cat_cols]), function(i){
                                                      unique_values = unique(train_dataset[, i])
                                                      selectInput(inputId = paste0("ip_", i), label = i, choices = sort(unique_values), width = 300, selected = min(unique_values))
                                                    }),
                                             ),
                                             
                                             column(width = 3,
                                                    
                                                    lapply(colnames(train_dataset[, cat_cols]), function(i){
                                                      unique_values = unique(train_dataset[, i])
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
                                           
                                  ),#Single Prediction end
                                  
                                  tabPanel("Single Prediction Result",


                                           fluidRow(
                                             column(width = 3, align = "right", offset = 3, h3("Probability of Default: ")),
                                             column(width = 3, align = "left", h3(textOutput("op_single_pred_text2"))),
                                             #column(width = 3, align = "right", h2("Expected Loss: ")),
                                             #column(width = 3, align = "left", h2(textOutput("op_single_pred_expected_loss"), style = "color:red")),
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




                                  ) # single prediction result end
                      ) # single prediction tab end (within prediction end)
             ) #model prediction end
  ) #nav bar end
  
)


#####################        SINGLE PREDICTION      ##########################

server <- function(input, output, session){


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
  print(str(train_dataset))
  single_row_df <- train_dataset[1, ]
  for(i in colnames(single_row_df)){
    if(i %in% numeric_cat_cols | i %in% int_cols)
      single_row_df[, i] <- as.numeric(input[[paste0("ip_",i)]])
    else
      single_row_df[, i] <- as.character(input[[paste0("ip_",i)]])
  }

  print(single_row_df)
  print(str(single_row_df))
  single_pred_df <- daimojo::predict.mojo(model, single_row_df)
  print(single_pred_df[1,2])
  return(single_pred_df[1,2]) #Prediction of positive class - 1 row only available

}
)

output$op_single_pred_text1 <- renderText(paste0(round(fun_single_pred_from_mojo()*100,2), " %"))

output$op_single_pred_text2 <- renderText(paste0(round(fun_single_pred_from_mojo()*100,2), " %"))


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