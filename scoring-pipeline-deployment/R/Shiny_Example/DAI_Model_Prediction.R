# https://support.rstudio.com/hc/en-us/articles/200486138-Changing-R-versions-for-RStudio-desktop

##  http://docs.h2o.ai/driverless-ai/latest-stable/docs/userguide/r_install_client.html#prerequisites

#install.packages('curl') #given incorrectly as rcurl
#install.packages('jsonlite')
#install.packages('rlang')
#install.packages('methods')

#############################################################################################
##########                   INSTALL DRIVERLESSAI R CLIENT                        ###########
#############################################################################################
getwd()
setwd("/Users/felix/Code/h2oai/driverlessai-tutorials/scoring-pipeline-deployment/R/Shiny_Example/")
#install.packages('dai_1.9.1.tar.gz', type = 'source', repos = NULL)
library(dai)



#############################################################################################
##########                           DAI Connect                                  ###########
#############################################################################################
url = 'http://ec2-3-85-128-223.compute-1.amazonaws.com:12345'
username = 'h2oai'
password = 'i-0f244cddd419191cd'
dai.connect(uri = url, username = username, password = password)

#############################################################################################
##########                    DAI Model Prediction                                ###########
#############################################################################################
View(dai.list_models())
new_data = read.csv("CreditCard-test.csv")

final_model = dai.get_model(key = '6a8a4010-62d4-11eb-8429-0242ac110002')
new_data_dai = as.DAIFrame(new_data)
preds = predict(final_model, newdata = new_data_dai)

pred_shap_contribs = predict(final_model, newdata = new_data_dai, pred_contribs = TRUE)
pred_orig_contribs = predict(final_model, newdata = new_data_dai, pred_contribs = TRUE, pred_contribs_original = TRUE)
