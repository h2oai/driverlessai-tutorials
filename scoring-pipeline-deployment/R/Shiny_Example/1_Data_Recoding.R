################################################################################################
################                        DATA PROCESSING                         ################
################################################################################################

setwd("/Users/felix/Code/h2oai/driverlessai-tutorials/scoring-pipeline-deployment/R/Shiny_Example/")

dataset <- read.csv("CreditCard.csv", header = TRUE, stringsAsFactors = TRUE)
str(dataset)

#### remove ID column ####
dataset = dataset[-c(1)]
names(dataset)



#### Recoding GENDER
table(dataset$SEX)
dataset$SEX <- ifelse(dataset$SEX == 1, "Male", "Female")
table(dataset$SEX)

#### Recoding EDUCATION
table(dataset$EDUCATION)
dataset$EDUCATION[dataset$EDUCATION > 3] <- "Others"
dataset$EDUCATION[dataset$EDUCATION == 0] <- "No Schooling"
dataset$EDUCATION[dataset$EDUCATION == 1] <- "Graduate School"
dataset$EDUCATION[dataset$EDUCATION == 2] <- "University"
dataset$EDUCATION[dataset$EDUCATION == 3] <- "High School"
table(dataset$EDUCATION)

#### Recoding MARITAL STATUS
table(dataset$MARRIAGE)
dataset$MARRIAGE[dataset$MARRIAGE == 0 | dataset$MARRIAGE == 3] <- "Others"
dataset$MARRIAGE[dataset$MARRIAGE == 1] <- "Married"
dataset$MARRIAGE[dataset$MARRIAGE == 2] <- "Single"
table(dataset$MARRIAGE)

#### Target
table(dataset$default.payment.next.month)
dataset$default.payment.next.month = ifelse(dataset$default.payment.next.month==0, "0_Non-Default", "1_Default")

write.csv(dataset, "CreditCardRe.csv", row.names = FALSE)
