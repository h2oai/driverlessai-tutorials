Time Series pipeline with Test Time Augmentation
===============================================

Sample code to explain how an end to end automated pipeline can be implemented for Time Series prediction problems using H2O Driverless AI.

In this example we will

1. Create a Time Series dataset using [TSimulus][1], a realistic time series generator.
2. Using the dataset, we will train a time series experiment using [H2O Driverless AI][2].
3. Next, we download the scoring pipeline from the trained experiment and deploy it in a conda environment.
4. Finally, we will use the python scoring module to predict future values.
5. While scoring, we will use [Test Time Augmentation (TTA)][4] technique to augment additional data to allow us to predict beyond forecast horizon.

Pre-requisites
--------------

1. A working Linux based system which acts as your working environment. 
2. A working setup of [H2O Driverless AI][2]. This could be running on the same system as your working system.
3. Working [Miniconda][3] installation on the working environment to create conda environments.
4. Clone this repository and `cd` to this directory.

Creating Timeseries dataset
---------------------------

Using the [Tsimulus][2] tool, we generate a sample time-series dataset for a hypothetical restaurant chain.

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



[1]: https://tsimulus.readthedocs.io/en/latest/
[2]: https://www.h2o.ai/products/h2o-driverless-ai/
[3]: https://docs.conda.io/en/latest/miniconda.html
[4]: http://docs.h2o.ai/driverless-ai/latest-stable/docs/userguide/time-series.html#using-a-driverless-ai-time-series-model-to-forecast