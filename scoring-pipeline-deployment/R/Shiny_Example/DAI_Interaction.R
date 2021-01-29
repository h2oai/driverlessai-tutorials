
# https://support.rstudio.com/hc/en-us/articles/200486138-Changing-R-versions-for-RStudio-desktop

##  http://docs.h2o.ai/driverless-ai/latest-stable/docs/userguide/r_install_client.html#prerequisites

#install.packages('curl') #given incorrectly as rcurl
#install.packages('jsonlite')
#install.packages('rlang')
#install.packages('methods')

#############################################################################################
##########                   INSTALL DRIVERLESSAI R CLIENT                        ###########
#############################################################################################
#install.packages('~/Downloads/dai_VERSION.tar.gz', type = 'source', repos = NULL)
getwd()
setwd("/Users/felix/Code/h2oai/driverlessai-tutorials/scoring-pipeline-deployment/R/Shiny_Example/")
#install.packages('dai_1.9.1.tar.gz', type = 'source', repos = NULL)
library(dai)

#############################################################################################
##########                           DAI Connect                                  ###########
#############################################################################################
url = 'http://ec2-54-90-95-211.compute-1.amazonaws.com:12345'
username = 'h2oai'
password = 'i-06f3f3d6483e42c74'
dai.connect(uri = url, username = username, password = password)

#############################################################################################
##########                    DAI Data Upload/Delete                              ###########
#############################################################################################
dataset_daiFrame = as.DAIFrame(dataset)
#or
cc_dai <- dai.upload_dataset("CreditCardRe.csv", progress = TRUE)

cc_dai <- dai.get_frame('6b342104-621e-11eb-aa3e-0242ac110002')


View(dai.list_datasets())
dai_frame <- dai.get_frame('df7830d8-621d-11eb-aa3e-0242ac110002')
dai.rm(dai_frame)
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
  progress = TRUE)
)

### Distribution
dai.dotplot(cc_dai, variable_name = 'LIMIT_BAL', mark = "point")
dai.histogram(cc_dai, variable_name = 'LIMIT_BAL', number_of_bars = 30)

## Linear Regression
dai.loess_regression_plot(cc_dai, x_variable_name = 'BILL_AMT1', y_variable_name = 'BILL_AMT2' )
dai.linear_regression_plot(cc_dai, x_variable_name = 'PAY_AMT1', y_variable_name = 'PAY_AMT2' )

#############################################################################################
##########                         DAI Split Dataset                              ###########
#############################################################################################

dai.split_dataset(
  cc_dai,
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

train_dai_frame = dai.get_frame(key = '1962971a-6229-11eb-ad8b-0242ac110002')
test_dai_frame = dai.get_frame(key = '1962d8f6-6229-11eb-ad8b-0242ac110002')

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

simple_model = dai.train(training_frame = train_dai_frame, target_col = 'default.payment.next.month', is_classification = TRUE,
          is_timeseries = FALSE, is_image = FALSE, testing_frame = test_dai_frame, scorer = 'AUC',
          accuracy = 1, time = 1, interpretability = 10, experiment_name = 'R_Triggered_CC_Basic')

default_model = dai.train(training_frame = train_dai_frame, target_col = 'default.payment.next.month', is_classification = TRUE, experiment_name = 'R_Triggered_CC_Suggested_Params')


expert_model= dai.train(training_frame = train_dai_frame, target_col = 'default.payment.next.month', is_classification = TRUE,
          is_timeseries = FALSE, is_image = FALSE, testing_frame = test_dai_frame, scorer = 'AUC',
          accuracy = 1, time = 1, interpretability = 10, experiment_name = 'R_Triggered_CC_Config_Override', 
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

fetched_model = dai.get_model(key = 'b54a906c-623b-11eb-ad8b-0242ac110002')
dai.rm(aborted_model)

dai.set_model_desc(fetched_model, 'R_Triggered_CC_SuggestedParams')

#############################################################################################
##########                        DAI Reuse/Retrain a Model                       ###########
#############################################################################################

