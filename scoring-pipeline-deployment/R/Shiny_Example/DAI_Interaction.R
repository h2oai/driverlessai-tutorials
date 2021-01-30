
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
url = 'http://ec2-18-212-191-247.compute-1.amazonaws.com:12345'
username = 'h2oai'
password = 'i-0f244cddd419191cd'
dai.connect(uri = url, username = username, password = password)

#############################################################################################
##########                    DAI Data Upload/Delete                              ###########
#############################################################################################
dataset_daiFrame = as.DAIFrame(dataset)
#or
cc_dai <- dai.upload_dataset("CreditCardRe.csv", progress = TRUE)

View(dai.list_datasets())

cc_dai <- dai.get_frame('6e2f6060-62cf-11eb-8429-0242ac110002')

dai.rm(cc_dai)
View(dai.list_datasets())

cc_df <- as.data.frame(cc_dai)
str(cc_df)

#############################################################################################
##########                    DAI Dataset Visuals                                 ###########
#############################################################################################

library(vegawidget)

### Parallel Coordinates Plot
dai.parallel_coordinates_plot(cc_dai)
dai.parallel_coordinates_plot(
  cc_dai,
  variable_names = NULL,
  permute = FALSE,
  transpose = FALSE,
  cluster = TRUE,
  render = TRUE,
  progress = TRUE
)

### Distribution
dai.dotplot(cc_dai, variable_name = 'PAY_0', mark = "point")
dai.histogram(cc_dai, variable_name = 'LIMIT_BAL', number_of_bars = 5)

## Linear Regression
dai.loess_regression_plot(cc_dai, x_variable_name = 'BILL_AMT1', y_variable_name = 'BILL_AMT2' )
dai.linear_regression_plot(cc_dai, x_variable_name = 'PAY_AMT1', y_variable_name = 'PAY_AMT2' )

#############################################################################################
##########                         DAI Split Dataset                              ###########
#############################################################################################

dai.split_dataset(
  dataset = cc_dai,
  output_name1 = 'CreditCardRe_Train',
  output_name2 = 'CreditCardRe_Test',
  ratio = 0.8,
  seed = 1234,
  target = 'default.payment.next.month',
  fold_col = NULL,
  time_col = NULL,
  progress = TRUE
)
View(dai.list_datasets())

#############################################################################################
##########                        DAI New Experiment                              ###########
#############################################################################################

train_dai_frame = dai.get_frame(key = '452a0218-62d1-11eb-8429-0242ac110002')
test_dai_frame = dai.get_frame(key = '452a3062-62d1-11eb-8429-0242ac110002')



View(dai.list_models())
aborted_model = dai.get_model(key = 'ec65f432-62d2-11eb-8429-0242ac110002')
aborted_model
dai.rm(aborted_model)

default_model = dai.train(training_frame = train_dai_frame,
                          target_col = 'default.payment.next.month',
                          is_classification = TRUE,
                          experiment_name = 'R_Triggered_CC_Default')

simple_model = dai.train(training_frame = train_dai_frame,
                         target_col = 'default.payment.next.month',
                         is_classification = TRUE,
                         is_timeseries = FALSE,
                         is_image = FALSE,
                         testing_frame = test_dai_frame,
                         scorer = 'F1',
                         accuracy = 1,
                         time = 1,
                         interpretability = 10,
                         experiment_name = 'R_Triggered_CC_Basic')


expert_model= dai.train(training_frame = train_dai_frame,
                        target_col = 'default.payment.next.month',
                        is_classification = TRUE,
                        testing_frame = test_dai_frame,
                        scorer = 'AUC',
                        accuracy = 1,
                        time = 1,
                        interpretability = 10,
                        experiment_name = 'R_Triggered_CC_Config_Override', 
                        config_overrides = c('make_autoreport = true',
                                             'autodoc_population_stability_index = true',
                                             'recipe = "auto"',
                                             'enable_tensorflow = "on"',
                                             'enable_xgboost_gbm = "off"',
                                             'enable_lightgbm = "off"',
                                             'make_python_scoring_pipeline = "off"',
                                             'make_mojo_scoring_pipeline = "off"'
                               ))
View(dai.list_models())

suggested_params = dai.suggest_model_params(
  training_frame = train_dai_frame,
  target_col = 'default.payment.next.month',
  is_classification = TRUE,
  is_timeseries = FALSE,
  is_image = FALSE,
  config_overrides = "",
  cols_to_drop = NULL
)

View(suggested_params)
suggested_params_model = do.call(dai.train, suggested_params)

View(dai.list_models())
fetched_model = dai.get_model(key = '61e18f70-62d6-11eb-8429-0242ac110002')
dai.set_model_desc(fetched_model, 'R_Triggered_CC_SuggestedParams')
dai.rm(fetched_model)


#############################################################################################
##########                        DAI Reuse/Refit a Model                       ###########
#############################################################################################

View(dai.list_models())
fetched_model = dai.get_model(key = '61e18f70-62d6-11eb-8429-0242ac110002')

summary(fetched_model)

another_expert_model= dai.train(training_frame = train_dai_frame,
                        target_col = 'default.payment.next.month',
                        is_classification = TRUE,
                        testing_frame = test_dai_frame,
                        scorer = 'MCC',
                        accuracy = 1,
                        time = 1,
                        interpretability = 10,
                        experiment_name = 'R_Triggered_CC_Config_Override_Same_Params', 
                        resumed_model = fetched_model,
                        resume_method = 'same')

another_expert_model= dai.train(training_frame = cc_dai,
                                target_col = 'default.payment.next.month',
                                is_classification = TRUE,
                                testing_frame = test_dai_frame,
                                scorer = 'MCC',
                                accuracy = 1,
                                time = 0,
                                interpretability = 10,
                                experiment_name = 'R_Triggered_CC_Config_Override_Same_Params', 
                                resumed_model = fetched_model,
                                resume_method = 'refit')



