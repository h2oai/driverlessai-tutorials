Python Scoring Pipeline using PySpark
============================================

This directory contains sample code that explains the steps needed to deploy a python scoring pipeline
obtained from H2O Driverless AI on a Spark cluster.


Prerequisites
-------------

The following pre-requisites are needed.
1. Conda and [conda-pack](https://conda.github.io/conda-pack/) installed. This is needed to build Python environment/code to distribute among cluster.
- To install conda-pack:  `conda install -c conda-forge conda-pack`
2. Install `openblas` on all nodes (driver and executors that will run the Python code).
- Install openblas on Spark driver and all executors:
  a. CentOS: `sudo yum install -y  openblas-devel` or use rpm 0.3.3: https://centos.pkgs.org/7/epel-x86_64/openblas-0.3.3-2.el7.x86_64.rpm.html
  b. Ubuntu: `sudo apt-get install libopenblas-dev`
3. Install git on Spark driver and all executors, e.g. `sudo yum install git`

Code Structure
--------------

The process assumes a directory structure as below:

```
top-dir: A directory with the below structure. This example uses the home directory of current user.
- README.md: This file with the details you are reading
- py_scorer_testing: A directory that contains files to be used for deployment
    - scorer.zip: The DAI python scoring pipeline. (You need to put this file here to extract files needed below)
    - license.sig: Valid Driverless AI license file. (You need to provide your license file here)
    - get_predictions.py: PySpark script (example given) used for running batch scoring
    - py_scorer_env.tar.gz: conda-pack generated following instructions below
    - dai_contrib.tar.gz: (optional) compressed tmp folder generated following instructions below (necessary if your model used custom recipes)
```

Instructions
------------

1. Upload Python Scoring Pipeline (scorer.zip) and license.sig onto Spark driver.
2. Copy your input_dataset.csv to HDFS for the cluster to access. Or, if using spark locally, store the dataset on the driver.
3. Create scorer folder and unzip scorer on Spark driver.
`mkdir py_scorer_testing`
`cd py_scorer_testing`
Move scorer.zip into py_scorer_testing
`unzip scorer.zip`

4. Create Python Env using environment.yml found in scorer.zip:
`conda env create --name py_scorer_env -f scoring-pipeline/environment.yml`
`conda activate py_scorer_env`
If model was created before DAI 1.8.5, you will need to install gitdb:
`pip install --upgrade gitdb2==2.0.6 gitdb==0.6.4`

5. Create conda-pack of new Env:
`cd py_scorer_testing`
`conda env list` OR `conda list`
`conda pack -n py_scorer_env -o py_scorer_env.tar.gz`

6. Create tar.gz of DAI’s tmp folder (this step is necessary if your model used custom recipes)
`tar -czvf dai_contrib.tar.gz -C scoring-pipeline/tmp/contrib .`
Note that you cannot use tmp due to conflict of Spark already having tmp folder

7. Download `get_predictions.py` from this repo and add to `py_scorer_testing` folder

8. Set up env vars (some may not be needed for YARN cluster mode)
`export ARROW_PRE_0_15_IPC_FORMAT=1`  (due to [pyarrow issue](https://stackoverflow.com/questions/58269115/how-to-enable-apache-arrow-in-pyspark))  
`export DRIVERLESS_AI_LICENSE_FILE=~/py_scorer_testing/license.sig`
`export PYSPARK_PYTHON=./py_scorer_env/bin/python`
`export SPARK_HOME=/path/to/spark` (e.g. ~/spark/spark-2.4.5-bin-hadoop2.7)
`export HADOOP_CONF_DIR=/etc/hadoop/conf` (may need to modify if don't have default hadoop path)

9. Run `kinit` if Hadoop is secured with Kerberos

10. cd into conda envs, e.g. `cd ~/miniconda3/envs`

11. Submit Spark Job `get_predictions.py`
```
PYTHONIOENCODING=utf8 \
PYSPARK_PYTHON=./py_scorer_env/bin/python \
spark-submit \
--master yarn \
--deploy-mode cluster \
--num-executors 2 --driver-memory 2g --executor-memory 4g \
--archives ../../py_scorer_testing/py_scorer_env.tar.gz#py_scorer_env,../../py_scorer_testing/dai_contrib.tar.gz#tmp/contrib \
--conf spark.executorEnv.PATH=`echo $PATH` \
--conf spark.executorEnv.PYSPARK_PYTHON=./py_scorer_env/bin/python \
--conf spark.executorEnv.ARROW_PRE_0_15_IPC_FORMAT=1 \
--conf spark.executorEnv.PYTHONIOENCODING=utf8 \
--conf spark.yarn.appMasterEnv.PYTHONIOENCODING=utf8 \
--conf spark.yarn.appMasterEnv.PYSPARK_PYTHON=./py_scorer_env/bin/python \
--conf spark.executorEnv.DRIVERLESS_AI_LICENSE_KEY=`cat ~/py_scorer_testing/license.sig` \
--conf spark.driver.maxResultSize=2g \
~/py_scorer_testing/get_predictions.py hdfs:///user/path/to/input_dataset.csv hdfs:///user/path/to/output_dataset.csv
```
Note: utf encodings (used above) may be needed for certain NLP models and spark.executorEnv.PATH for initialization

Disclaimer
----------

The scoring pipeline wrapper code shared in this directory is created to provide you 
a sample starting point and is not intended to be directly deployed to production as is.
You can use this starting point and build over it to solve your deployment needs ensuring
that your security etc. requirements are met.
