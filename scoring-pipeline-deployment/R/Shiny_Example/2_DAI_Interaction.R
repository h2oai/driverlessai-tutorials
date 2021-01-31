
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
url = 'http://ec2-54-204-68-13.compute-1.amazonaws.com:12345'
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

dai_frame <- dai.get_frame('a4fbeb42-63cc-11eb-831f-0242ac110002')
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
  progress = TRUE
)

### Distribution
dai.dotplot(cc_dai, variable_name = 'PAY_0', mark = "point")
#dai.histogram(cc_dai, variable_name = 'LIMIT_BAL', number_of_bars = 5)

## Linear Regression
dai.loess_regression_plot(cc_dai, x_variable_name = 'BILL_AMT1', y_variable_name = 'BILL_AMT2' )
#dai.linear_regression_plot(cc_dai, x_variable_name = 'PAY_AMT1', y_variable_name = 'PAY_AMT2' )

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

train_dai_frame = dai.get_frame(key = '1cd2a352-63cf-11eb-831f-0242ac110002')
test_dai_frame = dai.get_frame(key = '1cd2cf12-63cf-11eb-831f-0242ac110002')

View(train_dai_frame)
View(train_dai_frame$columns)

#############################################################################################
##########                        DAI New Experiment                              ###########
#############################################################################################

View(dai.list_models())

default_model = dai.train(training_frame = train_dai_frame,
                          target_col = 'default.payment.next.month',
                          is_classification = TRUE,
                          experiment_name = 'Default',
                          testing_frame = test_dai_frame)

simple_model = dai.train(training_frame = train_dai_frame,
                         target_col = 'default.payment.next.month',
                         is_classification = TRUE,
                         testing_frame = test_dai_frame,
                         scorer = 'F1',
                         accuracy = 1,
                         time = 1,
                         interpretability = 10,
                         experiment_name = 'Basic')


glm_model= dai.train(training_frame = train_dai_frame,
                        target_col = 'default.payment.next.month',
                        is_classification = TRUE,
                        testing_frame = test_dai_frame,
                        scorer = 'AUC',
                        accuracy = 1,
                        time = 1,
                        interpretability = 10,
                        experiment_name = 'Config_Override', 
                        config_overrides = c('make_autoreport = true',
                                             'autodoc_population_stability_index = true',
                                             'enable_glm="on"',
                                             'enable_decision_tree="off"',
                                             'enable_xgboost_gbm = "off"',
                                             'enable_lightgbm = "off"',
                                             'make_python_scoring_pipeline = "off"',
                                             'make_mojo_scoring_pipeline = "off"'
                               ))
View(dai.list_models())

# suggested_params = dai.suggest_model_params(
#   training_frame = train_dai_frame,
#   target_col = 'default.payment.next.month',
#   is_classification = TRUE,
#   is_timeseries = FALSE,
#   is_image = FALSE,
#   config_overrides = "",
#   cols_to_drop = NULL
# )
# 
# View(suggested_params)
# suggested_params_model = do.call(dai.train, suggested_params)

View(dai.list_models())
fetched_model = dai.get_model(key = 'c1224714-63d4-11eb-831f-0242ac110002')
dai.set_model_desc(fetched_model, 'prod_model')
#dai.rm(fetched_model)


#############################################################################################
##########                        DAI Reuse/Refit a Model                         ###########
#############################################################################################

View(dai.list_models())

summary(fetched_model)

another_expert_model= dai.train(training_frame = train_dai_frame,
                        target_col = 'default.payment.next.month',
                        is_classification = TRUE,
                        testing_frame = test_dai_frame,
                        scorer = 'AUCPR',
                        experiment_name = 'NewExpSameParams', 
                        resumed_model = fetched_model,
                        resume_method = 'same')
### ^^ When trying new experiments with same parameters, config_override changes are NOT used

refit_expert_model= dai.train(training_frame = cc_dai,
                                target_col = 'default.payment.next.month',
                                is_classification = TRUE,
                                testing_frame = test_dai_frame,
                                scorer = 'MCC',
                                accuracy = 1,
                                time = 0,
                                interpretability = 10,
                                experiment_name = 'RefitFinalModel', 
                                resumed_model = fetched_model,
                                resume_method = 'refit')

### ^^ When refitting final model, time setting is forced to 0


#############################################################################################
##########                    Retrieving / Downloading Artefacts                  ###########
#############################################################################################

View(dai.list_models())

final_model = dai.get_model(key = '0e856d32-63db-11eb-831f-0242ac110002')

#####   Predictions  #####
dai.autoreport(final_model, path = "../", force = TRUE, progress = TRUE)

#####   Predictions  #####
dai.download_file(final_model$train_predictions_path, dest_path = "../", force = TRUE,  progress = TRUE)
dai.download_file(final_model$test_predictions_path, dest_path = "../", force = TRUE,  progress = TRUE)

##### Summary and Log Files #####
dai.download_file(final_model$summary_path, dest_path = ".", force = TRUE, progress = TRUE)
dai.download_file(final_model$log_file_path, dest_path = ".", force = TRUE, progress = TRUE)

##### Download MOJO #####
dai.download_mojo(final_model, path = getwd(), force = TRUE, progress = TRUE)


#############################################################################################
##########         MLI Interpretation - CAUTION - Low Level Code / BUG            ###########
#############################################################################################

# library(jsonlite)
# 
# dai.interpret_model <- function(model, dataset, target_col, progress = TRUE) {
#   print(model$key)
#   print(dataset$key)
#   key <- dai:::.dai_do_rpc("api_run_interpretation", list("interpret_params" = list(
#     dai_model = list(key = unbox(model$key), display_name = unbox(model$description)),
#     dataset = list(key = unbox(dataset$key), display_name = unbox(dataset$name)),
#     target_col = unbox(target_col),
#     use_raw_features = unbox(TRUE),
#     prediction_col = unbox(''),
#     weight_col = unbox(''),
#     drop_cols = list(),
#     klime_cluster_col = unbox(''),
#     nfolds = unbox(0),
#     sample = unbox(TRUE),
#     sample_num_rows = unbox(-1),
#     qbin_cols = list(),
#     qbin_count = unbox(0),
#     lime_method = unbox("k-LIME"),
#     dt_tree_depth = unbox(3),
#     vars_to_pdp = unbox(10),
#     config_overrides = NULL,
#     dia_cols = list()
#   )))
#   
#   print("key is set")
#   print(key)
#   
#   return(dai:::wait_for_job(function() dai:::get_interpretation_job(key), progress = progress)$entity)
# }
# 
# mli <- dai.interpret_model(final_model, train_dai_frame, 'default.payment.next.month')






