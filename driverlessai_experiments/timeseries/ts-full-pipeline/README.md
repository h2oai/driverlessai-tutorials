Time Series pipeline with Test Time Augmentation
===============================================


Overview
--------
This directory contains sample code to demonstrate an end to end pipeline implementation for Time Series problems using H2O Driverless AI. 

There are other examples in this repository which also show how to do time-series with DAI, but in this example we use the scoring pipeline to predict future data instead of using the prediction endpoint on the Driverless AI server.  


We start by training a time-series experiment in Driverless AI. Then proceed to create a conda based python environment in which the python scoring pipeline is deployed. Finally, we show how the scoring module can be used as an imported module or an HTTP API endpoint for scoring. 

Since this example deals with [Test Time Augmentation][4] and the rolling window approach for scoring (details below), we are required to use the python scoring pipeline. As if this writing, MOJO pipeline does not support TTA based scoring for time-series experiments.


Pre-requisites
--------------
1. A working Linux system which acts as your working environment. 
2. A working setup of [H2O Driverless AI][2]. This could be running on the same system as your working system.
3. Working [Miniconda][3] installation on the working environment to create conda environments.
4. Clone this repository and `cd` to the directory containing this README file. This is your working directory and all commands are to be executed in this directory.


Pipeline Steps
--------------
The below steps constitute the pipeline, where each step uses the output of the previous steps. The file names in this directory start with the step numbers to help correlate what each file is doing

- __Step 1__: Create a master Time Series dataset using [TSimulus][1], a realistic time series generator. This is a master dataset from which we can cut/extract experiment specific datasets.
- __Step 2__: From the master dataset, we cut/extract training, gap and test datasets to be used for experiments.
- __Step 3__: We train time-series experiment using [H2O Driverless AI][2] on the experiment specific data. This step also downloads the scoring pipelines (Mojo and Python) and other experiment artifcats that can be used later if needed.
- __Step 4__: We generate rolling window based [Test Time Augmented (TTA)][4] scoring files from gap and test datasets generated in step 2. In general, this step simulates the passage of time and will not be needed in a real world implementation.
- __Step 5__: Finally, we score the rolling window based TTA data generated in the previous step using the scoring pipeline obtained from an experiment trained in Step 3. This step also takes care of creating a python environment and installing required dependencies and modules for Driverless AI's scoring pipeline to work in that environment.


Important Definitions
---------------------

Before you proceed, we strongly recommend you read the below two sections in DAI documentation

- [Understanding Gap and Horizon][5]
- [Forecasting using Test Time Augmentation][4]

I believe that reading the above sections makes clear the definition of the below terms

![Training, Gap and Horizon](http://docs.h2o.ai/driverless-ai/latest-lts/docs/userguide/_images/time_series_horizon.png)

_Figure 1: DAI time-series experiment configuration without TTA or Rolling Window_

- __Training data duration__: The period of time between which the data available is used for training the model 
- __Gap duration__ : The period of time between the training period and testing period.
- __Test data duration/Horizon__ : This is the duration of data for which the model is expected to provide a prediction based on the patterns it learns from the Training data. Incidentally, this is also the duration of time for which data needs to be passed for scoring into the `score_batch` method of the scoring module.

> DAI scoring pipeline for Time Series experiment cannot predict beyond the Test Data Duration (Horizon) that is configured during experiment training.


 
To predict beyond that time period you need to either (1) retrain a new experiment on new data OR (2) use the Test Time Augmentation (TTA) technique to update the earlier model with new data at the time for scoring and then score on future data as needed.
 
![Rolling Window and Test Time Augmentation](https://raw.githubusercontent.com/h2oai/driverlessai-tutorials/master/driverlessai_experiments/timeseries/ts-full-pipeline/images/TTA-RollWindow-duration.png)

###### _Figure 2: DAI time-series experiment configuration with TTA and Rolling Window_
 
When using TTA and Rolling Window concept we need to introduce two new terms 

- __Prediction Duration__ : This is the duration configured as the test data duration (horizon) while training the DAI experiment. 

    If you do not want to predict beyond the Test Data Duration configured during experiment training using the experiment's scoring pipeline, then in that case __Prediction Duration (PD)__ will be the same as __Test Data Duration/Horizon__ and the situation is as depicted in Figure 1.
    
    When using TTA, this is the Horizon during experiment training. During scoring, it will be the duration of data passed to score for each invocation of `score_batch` method of the scoring module. 

- __Rolling Duration__ : This is the amount of duration by which we move ahead (roll) in time before we score again for next prediction duration data. It would be more clear in figure 2.

> When TTA is used, technically there does not exist a horizon beyond which TTA will stop scoring. However, for practical reasons like reduced accuracy and/or large scoring data frame sizes, it would so happen that you will need to retrain. That permissible duration till which you are ok to deal with less accuracy and bit slower performance before retraining, kind of becomes the actual __Test Data Duration/Horizon__ in the TTA scenario.

 
 Directory Structure
 -------------------
As specified in step 4 of 'Pre-requisites' section, the working directory for this pipeline to execute all commands is the one that contains this README file. 

This directory is the root of the below directory tree denoted by `.` at the top of the tree. All paths shows below are relative to this directory.
 
```
.
├── 01-generate-data.sh
├── 01_process_full_TS_csv.py
├── 02-create-experiment-data.sh
├── 02_extract_experiment_datasets.py
├── 03-default-experiment-configs.json
├── 03_run_experiment.py
├── 03-run-experiment.sh
├── 04-create-tta-scoring-files.sh
├── 04_generate_tta_files.py
├── 05_score_tta_files.py
├── 05-score-tta-files.sh
├── data_fullts                                                                      # dir containing full time series dataset, generated in Step 01
│   ├── fullts1617.csv                                                               # contains full time series dataset CSV, pickle and svg plot files
│   ├── fullts1617.pickle
│   └── fullts1617_plot.svg
├── environment.yml
├── experiment_data
│   ├── s2016-01-01-e2016-02-29-gd0-td7-m15                                          # Experiment data file contains train, gap and test datasets generated in step 02
│   │   ├── test.csv                                                                 # Generated in Step 02 when the dataset files are created.
│   │   ├── test.pickle                                                              # Name convention helps understand start and end dates, gap and test duration and
│   │   ├── test_plot.svg                                                            # amount of missing data in them (%)
│   │   ├── train.csv
│   │   ├── train.pickle
│   │   ├── train_plot.svg
│   │   ├── experiment_runs                                                          # Experiment Runs directory. Contains artifacts for all experiments run on this directory
│   │   │   ├── hewagadu                                                             # An experiment that was executed on this data, is contains the experiment configuration
│   │   │   │   ├── experiment-config.json                                           # logs and scoring pipelines which are used for scoring. Created in step 03.
│   │   │   │   ├── experiment.json                                                  # Name of directory matches the name of DAI experiment in GUI
│   │   │   │   ├── h2oai_experiment_summary_hewagadu.zip
│   │   │   │   ├── mojo.zip
│   │   │   │   ├── scorer.zip
│   │   │   │   └── scoring-pipeline
│   │   │   │       ├── client_requirements.txt
│   │   │   │       ├── common-functions.sh
│   │   │   │       ├
│   │   │   │       ├   .. some files deleted here for brevity ..
│   │   │   │       ├
│   │   │   │       ├── http_server.py
│   │   │   │       ├── scoring_h2oai_experiment_hewagadu-1.0.0-py3-none-any.whl
│   │   │   └── migafepo
│   │   │       ├── experiment-config.json
│   │   │       ├── experiment.json
│   │   │       ├── h2oai_experiment_summary_migafepo.zip
│   │   │       ├── mojo.zip
│   │   │       └── scorer.zip
│   │   └── tta-scoring-data-pd24-rd1                                                # TTA Scoring data generated in step 4 from  gap and test data for this experiment_data
│   │       └── score                                                                # Score directory contains TTA files used for scoring using an experiment executed in Step 3
│   │       │   ├── 00000-ss2016-03-01 00:00:00-se2016-03-01 23:00:00.csv
│   │       |   ├── 00001-ss2016-03-01 01:00:00-se2016-03-02 00:00:00.csv            # File name contains start and end time stamp of scoring/prediction window.
│   │       |   ├──
│   │       |   ├── .. some files deleted here for brevity ..
│   │       |   ├──
│   │       |   ├── 00143-ss2016-03-06 23:00:00-se2016-03-07 22:00:00.csv
│   │       |   └── 00144-ss2016-03-07 00:00:00-se2016-03-07 23:00:00.csv
│   │       ├── predicted                                                            # Contains scoring/prediction outcomes for the TTA files in the score directory above
│   │       │   └── hewagadu                                                         # using the scoring pipeline of the experiment denoted but this experiment name directory
│   │       │       ├── 00000-api-m0.7090902316877895.csv                            # in predicted (i.e. hewagadu in this case)
│   │       │       ├── 00000-mod-m0.7090902316877895.csv
│   │       │       ├── 00001-api-m0.740253435638484.csv                             # Files are scored using Python Module or API using HTTP server endpoint
│   │       │       ├── 00001-mod-m0.7158677893980059.csv                            # identified by 'mod' or 'api' in the file name.
│   │       │       ├                                                                # Use the file index e.g. '00001' to match with corresponding scoring data file
│   │       │       ├   .. some files deleted here for brevity ..
│   │       │       ├
│   │       │       ├── 00143-api-m10.332754683563603.csv
│   │       │       ├── 00143-mod-m0.6643596583268168.csv
│   │       │       ├── 00144-api-m10.323628588233568.csv
│   │       │       └── 00144-mod-m0.6757308137696649.csv
├── README.md
├── scratch.py
├── ts-definition.json
└── tsimulus-cli.jar
``` 


Step 01. Create Master time-series dataset
------------------------------------------
Using the [Tsimulus][2] tool, we generate a sample time-series dataset for a hypothetical restaurant chain. The time-series definition is specified in in `ts-definition.json` file in this directory which is passed as input to `-d` option. 

- The dataset includes hourly aggregated sales data for 4 products across 2 restaurants
- Products are `TACO, BURGER, SODA, COFFEE`
- Restaurants are `S1` and `S2`
- Data range is from `1 Jan 2016 00:00:00` hours till `31 Dec 2017 23:00:00`
- Use the below mentioned wrapper script to generate the time series data in `.csv` and `.pickle` format and plot the time series as a `.svg`

```bash
$ bash 01-generate-data.sh --help

Usage:
  bash 01-generate-data.sh -d <tsdf.json> -o <output> [-f | --force] [-h | --help]
Options:
  -d <tsdf.json>            Timeseries definition file. Must be JSON file.
  -o <output>               Output file name. Will generate output.csv, <output>.pickle, and <output>.svg files
  -f, --force               Force overwrite of output file.
  -h, --help                Display usage information.
Details:
  Creates the master time series dataset for this pipeline demo. It simulates a larger database
  from which section of data will be extracted to train and then predict on
```

Outcome of this command is the creation of the `.csv`, `.pickle` and `.svg` files in the `data_fullts` directory.


Step 02. Create Experiment data
-------------------------------
Using the `.pickle` file created in the `data_fullts` folder in Step 1, this step extracts train, gap and test data from the master time-series dataset. It can optionally simulate missing data based on the proportion (%) specified using the `-m` option.

```bash
$ bash 02-create-experiment-data.sh 

Usage:
  bash 02-create-experiment-data.sh -i <dataset.pickle> -s <train start date> -e <train end date> -g <gap> -t <test duration> [-m <misssing data %> ] [-h | --help]
Options:
  -i <dataset.pickle>         Full time series dataset, created by 01-generate-data script. Provide .pickle file
  -s <train start date>       Starting date for Train data YYYY-MM-DD format. Train dataset will start from 00:00:00.000 hours for that date.
  -e <train end date>         Ending date for Train data in YYYY-MM-DD format. Train dataset will include data for this date till 23:00:00 hours i.e. full 24 hour period.
  -g <gap duration>           Gap (in days) between last training date and first testing date.
  -t <test duration>          Duration (in days) for which we are generating test data. It starts from gap days after the last date in train dataset.
  -m <missing data %>         Proportion of target data that is missing in both Training and Test dataset. Optional, defaults to 0.
  -h, --help                  Display usage information.
Details:
  Creates train, gap and test datasets (csv and pickle) in the output directory. Also creates timeseries plots for train and test datasets. 
  The output directory will be created in the format sYYYYMMDD-eYYYYMMDD-gdG-tdF-mMP, where
  - sYYYYMMDD-eYYYYMMDD is the training dataset start and end date
  - gdG is the gap duration
  - tdF is the test duration
  - mMP is proportion of missing data in Train and Test datasets
  When the script is executed with certain inputs which results in an output directory that already exists, no action is taken.
```

Outcome of this command is the creation of the requisite files in the output directory as specified in the above details. The output directory is itself created in `experiment_data` directory in the working directory.

> **Note** - The `<test duration>` (in days) in the above command is the duration of Test Data Duration (Horizon) as depicted in Figure 2 above for the TTA based case. The Prediction Duration (PD) which differs from Test Data Duration in case of TTA is configured in the `num_prediction_periods` property of the experiment config JSON file.
 [Refer link for details](https://github.com/h2oai/driverlessai-tutorials/blob/26b9e1a567261562478d85f122cabd083f61fc4c/driverlessai_experiments/timeseries/ts-full-pipeline/03-default-experiment-configs.json#L24)


Step 03. Execute Experiment
---------------------------
Executes a Driverless AI experiment using the training data file (`train.csv`) in the experiment data directory (created in step 2) and the configuration specified by the config file in the current directory. Experiment settings are specified in the file `03-default-experiment-configs.json`. 

Take note of the environment variables that need to be specified for the Driverless AI server connection. 

```bash
$ bash 03-run-experiment.sh 

Usage:
  bash 03-run-experiment.sh -d <experiment_data_dir> -c <experiment_config_file> [-t | --test]  [-h | --help]
Options:
  -d <experiment_data_dir>         Path (relative to this script) to the experiment data directory containing train.csv and test.csv files
  -c <experiment_config_file>      Path (relative to this script) to the default experiment config settings. Dataset details not needed in file.
  -t, --test                       Include test dataset when executing the experiment (optional).
  -h, --help                       Display usage information.
Details:
  Executes an experiment on the Driverless AI server at DAI_HOST. The train dataset (train.csv) is obtained from 
  the experiment_data_dir. Experiment configuration is obtained from experiment_config_file. The dataset key information
  in experiment_config_file can be left as it is. It will be obtained at runtime. 
  
  The script expects below three environment variables to be set with Driverless AI connection information
  - DAI_HOST - Url where DAI is running. Include full URL till the port e.g. http://localhost:12345
  - DAI_USER - Username for connecting to Driverless AI
  - DAI_PASS - Password for the above user
  
  If the experiment completes successfully; python and mojo scoring pipelines are downloaded for the experiment. 
```

> **Note** - Refer to note in step 2 about how to configure Prediction Duration for an experiment, and how it links to Test Data Duration (specified in step 2) for a TTA use case.

Outcome is creation of a sub-directory, with the name of the experiment, in the `experiment_runs` directory. The `experiments_runs` directory will be created as a sub-directory of the directory specified as `experiment_run_dir`


Step 04. Create TTA scoring files.
----------------------------------
Generate scoring data files using the rolling window and Test Time Augmentation technique.

```bash
$ bash 04-create-tta-scoring-files.sh 

Usage:
  bash 04-create-tta-scoring-files.sh -i <experiment data dir> [-p <prediction duration> ] [-r <roll duration>] [-h | --help]
Options:
  -i <experiment data dir>    Experiment data directory containing train, gap, and test csv and pickle files
  -p <predict duration>       Duration (in hours) of data to predict in each scoring data frame. Optional, defaults to 24 hours i.e 1 day
  -r <roll duration>          Duration (in hours) by which to roll the data window and score for next predict duration. Optional, defaults to 1 hour
  -h, --help                  Display usage information.
Details:
  Creates TTA and rolling window based scoring dataframes (csv and pickle) in the output directory.
  The output directory will be created in the format tta-scoring-data-pdP-rdR, where
  - pdP is the predict duration
  - rdR is the rolling duration
  The output directory will be created as a subdirectory of <experiment data directory>
  When the script is executed with certain inputs which results in an output directory that already exists, no action is taken.

```
Outcome is the creation of scoring data in the output directory as specified above.


Step 05. Score TTA files
------------------------
Deploys the scoring pipeline downloaded from the experiment conducted in Step 3 in a conda environment and uses it for scoring the TTA files generated in step 4. One can use the python module or the HTTP api for scoring. 

```bash
$ bash 05-score-tta-files.sh 

 Usage:
  bash 05-score-tta-files.sh -e <experiment run dir> -s <scoring data dir> [-p <python|mojo>] [-m <module|api|api2>] [-h | --help]
Options:
  -e <experiment run dir>     Experiment run directory containing scorer.zip. Will have same name as experiment in Driverless AI
  -s <scoring data dir>       TTA scoring data directory created in step 04. Name will start with tta-scoring-data
  -p <python|mojo>            Optional, defaults to python. Use Driverless AI Python or Mojo (Java) pipeline for scoring
  -m <module|api|api2>        Optional, defaults to module. Score using python module in code or using HTTP JSON or DataFrame API endpoint
  -h, --help                  Display usage information.
Details:
  Scores the files in scoring data directory using the scoring pipeline for selected experiment. Also creates the necessary
  environments with dependencies for the scoring pipeline to work.
  Scoring files will be picked from the 'score' sub-directory of selected scoring data directory.
  Output files will be generated in the 'predicted' sub-directory of selected scoring data directory.
  Scoring method 'api' sends the prediction dataframe as JSON to API server for batch scoring; 'api2' uses base64 encoded Pandas DataFrame
```

Outcome is creation of scored files in the `predicted` sub-directory as mentioned above.

**WARNING** -  

> The example HTTP scorer `http_server.py`, included in all python scoring pipelines generated from DAI, will not work for TTA based scoring. It assumes the target column will never be present in the scoring dataframe (refer code in the `score_batch` function). However, for TTA based time-series scoring to work, the new actual data (target) generated as time rolls by (rolling window), needs to be passed in the scoring data frame along with the data it need to predict. I have provided 2 solutions/workarounds.

> I have provided a pandas dataframe based HTTP scoring server `11_http_server2.py` as an alternative. It accepts a payload of base64 encoded pandas Dateframe for scoring and returns a base64 encoded pandas dataframe with predictions as response.

> Additionally, I have also provided a way to dynamically hack the http_server.py file to make it work, in case you want to deploy an API that accepts JSON (since not all clients can accept JSON.) The hack is in `05-score-tta-files.sh` in function `score_tta_files_using_api`

> Additionally, I have provided a script `10_plot_score_metric.py` that compares the prediction outputs of all three methods and plots the prediction RMSE for all three approaches for the same fine to verify there is no deviance.


Step 06. Checking performance of scoring methods
------------------------------------------------
Once you are done with scoring in Step 5, for an experiment and TTA scoring dataset using all the three methods (`module|api|api2`), then you can go ahead and compare their performance against each other to check if they all perform similarly or if there is a divergence in prediction based on the method you choose. Additionally , you can also get a trend of how the prediction accuracy changes as we move away from the time denoting the end of Training data during experiment training phase.

> **Note** - Contrary to the above commands that are bash scripts this one uses python directly.

 ```bash
$ python 10_plot_score_metric.py 
Usage: 10_plot_score_metric.py [OPTIONS]
Try "10_plot_score_metric.py --help" for help.

Error: Missing option "-p" / "--predictions-dir".
```

Using the script you can generate the plot in the prediction directory containing the predictions. The plot would look as below. You see only one line here because all three scoring methods are giving you the exact same results. If the lines diverge then you would need to investigate further as to what is causing it.

![RMSE plot based on various methods](https://raw.githubusercontent.com/h2oai/driverlessai-tutorials/master/driverlessai_experiments/timeseries/ts-full-pipeline/images/metrics_plot.png)



[1]: https://tsimulus.readthedocs.io/en/latest/
[2]: https://www.h2o.ai/products/h2o-driverless-ai/
[3]: https://docs.conda.io/en/latest/miniconda.html
[4]: http://docs.h2o.ai/driverless-ai/latest-stable/docs/userguide/time-series.html#using-a-driverless-ai-time-series-model-to-forecast
[5]: http://docs.h2o.ai/driverless-ai/latest-lts/docs/userguide/time-series.html#gap-and-horizon