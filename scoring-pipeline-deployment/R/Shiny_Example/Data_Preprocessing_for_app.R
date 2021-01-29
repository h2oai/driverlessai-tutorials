#################     


library(dplyr)
library(daimojo)
options(scipen = 99999)

#install.packages("daimojo_2.4.8_x86_64-darwin.tar.gz", repos = NULL, type = "source") # to be downloaded from DAI under "Download MOJO Piepline"
# http://docs.h2o.ai/driverless-ai/latest-stable/docs/userguide/scoring-pipeline-cpp.html#downloading-the-scoring-pipeline-runtimes

#path set to driverlessai-tutorials
setwd("/Users/felix/Code/h2oai/driverlessai-tutorials/scoring-pipeline-deployment/R/Shiny_Example/")
dataset <- read.csv("CreditCard-train.csv", header = TRUE, stringsAsFactors = TRUE)
target <- "default.payment.next.month"


dataset$SEX <- ifelse(dataset$SEX == 1, "Female", "Male")
table(dataset$SEX)

dataset$EDUCATION[dataset$EDUCATION > 3] <- "Others"
dataset$EDUCATION[dataset$EDUCATION == 0] <- "No Schooling"
dataset$EDUCATION[dataset$EDUCATION == 1] <- "Graduate School"
dataset$EDUCATION[dataset$EDUCATION == 2] <- "University"
dataset$EDUCATION[dataset$EDUCATION == 3] <- "High School"


table(dataset$EDUCATION)

dataset$MARRIAGE[dataset$MARRIAGE == 0] <- "Others"
dataset$MARRIAGE[dataset$MARRIAGE == 1] <- "Married"
dataset$MARRIAGE[dataset$MARRIAGE == 2] <- "Single"
dataset$MARRIAGE[dataset$MARRIAGE == 3] <- "Others"

table(dataset$MARRIAGE)


class_vec <- data.frame(sapply(dataset, class))
class_vec$columns <- rownames(class_vec)
rownames(class_vec) <- NULL

colnames(class_vec) <- c("class", "variables")
class_vec$class <- as.character(class_vec$class)

class_vec <- class_vec[class_vec$variables != target, ]

class_vec <- class_vec[class_vec$variables != "ID", ]

int_cols <- class_vec$variables[class_vec$class %in% c("integer", "numeric")]

for(i in int_cols ){
  if(length(unique(dataset[,i])) < 50)
    class_vec$class[class_vec$variables == i] <- "numeric_cat"
  
}

summary(dataset)
str(dataset)

dataset$LIMIT_BAL <- as.numeric(dataset$LIMIT_BAL) #present as integer
dataset$PAY_0 <- as.numeric(dataset$PAY_0) #present as integer
dataset$PAY_2 <- as.numeric(dataset$PAY_2) #present as integer
dataset$PAY_3 <- as.numeric(dataset$PAY_3) #present as integer
dataset$PAY_4 <- as.numeric(dataset$PAY_4) #present as integer
dataset$PAY_5 <- as.numeric(dataset$PAY_5) #present as integer
dataset$PAY_6 <- as.numeric(dataset$PAY_6) #present as integer
dataset$PAY_AMT1 <- as.numeric(dataset$PAY_AMT1) #present as integer
dataset$PAY_AMT2 <- as.numeric(dataset$PAY_AMT2) #present as integer
dataset$PAY_AMT3 <- as.numeric(dataset$PAY_AMT3) #present as integer
dataset$PAY_AMT4 <- as.numeric(dataset$PAY_AMT4) #present as integer
dataset$PAY_AMT5 <- as.numeric(dataset$PAY_AMT5) #present as integer
dataset$PAY_AMT6 <- as.numeric(dataset$PAY_AMT6) #present as integer
dataset$BILL_AMT1 <- as.numeric(dataset$BILL_AMT1) #present as integer
dataset$BILL_AMT2 <- as.numeric(dataset$BILL_AMT2) #present as integer
dataset$BILL_AMT3 <- as.numeric(dataset$BILL_AMT3) #present as integer
dataset$BILL_AMT4 <- as.numeric(dataset$BILL_AMT4) #present as integer
dataset$BILL_AMT5 <- as.numeric(dataset$BILL_AMT5) #present as integer
dataset$BILL_AMT6 <- as.numeric(dataset$BILL_AMT6) #present as integer

#int_cols <- class_vec$variables[class_vec$class %in% c("integer", "numeric")]
#numeric_cat_cols <- class_vec$variables[class_vec$class %in% c("numeric_cat")]
#cat_cols <- class_vec$variables[class_vec$class %in% c("str", "factor", "character")]
#bool_cols <- class_vec$variables[class_vec$class %in% c("logical")]

summary(dataset)

predictor_colnames <- colnames(dataset)[colnames(dataset) != target]
predictor_colnames <- predictor_colnames[predictor_colnames != "ID"]

predictions_df <- read.csv("train_preds_custom.csv", header = TRUE)
colnames(predictions_df)[27] <- "prob_pred"


dataset_w_pred <- inner_join(dataset, predictions_df[, c("ID", "prob_pred")], by = "ID")
colnames(dataset_w_pred)[25] <- "Actual_Target"
dataset_w_pred$Actual_Target <- as.factor(dataset_w_pred$Actual_Target)

# TODO - REMOVE LICENSE KEY
Sys.setenv(DRIVERLESS_AI_LICENSE_KEY = paste0("paste your DAI License key here"))
m <- daimojo::load.mojo("mojo-pipeline/pipeline.mojo")

create.time(m)
uuid(m)
predict.mojo(m, dataset)

daimojo::predict(m, dataset)

