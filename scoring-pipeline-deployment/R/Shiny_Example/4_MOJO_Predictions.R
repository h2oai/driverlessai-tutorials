#############################################################################################
##########                         MOJO Model Prediction                          ###########
#############################################################################################
rm(list = ls())  # remove all objects including dai
#install dependencies and daimojo package
#install.packages('Rcpp')
#install.packages("~/Downloads/daimojo_2.5.8_x86_64-darwin.tar.gz", type = 'source', repos=NULL)

#install.packages('data.table')
getwd()
#setwd("/Users/felix/Code/h2oai/driverlessai-tutorials/scoring-pipeline-deployment/R/Shiny_Example/")

library(daimojo)
library(data.table)
### set DRIVERLESS_AI_LICENSE_KEY
Sys.setenv("DRIVERLESS_AI_LICENSE_KEY" = "paste your license here")
model = daimojo::load.mojo("mojo-pipeline/pipeline.mojo")
daimojo::create.time(model)
daimojo::feature.names(model)
col_class <- setNames(daimojo::feature.types(model), daimojo::feature.names(model))
daimojo::feature.types(model)
daimojo::missing.values(model)
daimojo::uuid(model)

new_data <- fread("./mojo-pipeline/example.csv", colClasses=col_class, header=TRUE, sep=",")
str(new_data)

daimojo::predict.mojo(m = model, newdata = new_data)

#############################################################################################
##########                         Data Prep for Shiny App                        ###########
#############################################################################################



