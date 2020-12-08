import pandas as pd
import numpy as np
from numpy import nan
from scipy.special._ufuncs import expit
import datatable as dt
INJECT_EXPERIMENT_IMPORT

scorer = Scorer()

input_dt = dt.fread("/data/input.csv", na_strings=['', '?', 'None', 'nan', 'NA', 'N/A', 'unknown', 'inf', '-inf', '1.7976931348623157e+308', '-1.7976931348623157e+308'])
output_dt = scorer.score_batch(input_dt, apply_data_recipes=False)
dt.Frame(output_dt).to_csv("/data/output.csv")