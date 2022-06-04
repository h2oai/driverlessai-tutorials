import sys
from pyspark.sql import SparkSession
from pyspark import SparkFiles
spark = SparkSession.builder.getOrCreate()

input_path = sys.argv[1]
output_path = sys.argv[2]
df = spark.read.csv(input_path, header=True, inferSchema=True)
names = df.columns

import pandas as pd
from pyspark.sql.functions import col, pandas_udf, size
from pyspark.sql.types import DoubleType, ArrayType

def predict(*series) -> pd.Series:
    import pandas as pd
    import numpy as np
    from numpy import nan
    from scipy.special._ufuncs import expit
    from scoring_h2oai_experiment_336ccd12_cbb4_11ea_8496_ac1f6b68b7be import Scorer # update with your key
    scorer = Scorer()
    merged = pd.concat(series, axis=1)
    merged.columns = names
    output = scorer.score_batch(merged)
    return pd.Series(output.values.tolist())

    
predict_udf = pandas_udf(predict, returnType=ArrayType(DoubleType()))
columns = [col(name) for name in df.columns]
withPredictions = df.withColumn("prediction", predict_udf(*columns))

# If working with multi-class, can expand prediction, e.g. 3 classes:
num_cols = withPredictions.withColumn("size", size(col("prediction"))).agg({"size": "max"}).head()[0] # To be performant, specify the value, e.g. num_cols=3
withPredictions = withPredictions.select(col("*"), *(col('prediction').getItem(i).alias(f'prediction_{i}') for i in range(num_cols)))
withPredictions = withPredictions.drop(col("prediction"))