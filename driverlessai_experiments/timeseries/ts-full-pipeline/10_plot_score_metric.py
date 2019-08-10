import click
import glob
import os
import re

import pandas as pd
import numpy as np
import seaborn as sns

from pandas.plotting import register_matplotlib_converters

@click.command()
@click.option('-p', '--predictions-dir', 'preds_dir', type=click.Path(exists=True,
                                                                      file_okay=False,
                                                                      dir_okay=True,
                                                                      readable=True,
                                                                      writable=True),
              required=True,
              help='Predictions data directory.')
def process(preds_dir):
    """
    Reads the scored files in predictions directory, extracts the metric from the filename and plots
    a graph to compare the metric divergence between API and Python module based scoring.

    :param preds_dir: Predictions data directory.
    :return: None
    """
    # First glob all module files
    mod_list = []
    mod_regex = re.compile(r'([0-9]{5})-mod-m([0-9.]+).csv')
    for m in glob.glob(f'{preds_dir}/*-mod-*.csv'):
        file_name = os.path.basename(m)
        capture_group = mod_regex.match(file_name)
        mod_list.append({
                            'order_id': capture_group.group(1),
                            'Module': capture_group.group(2)
                        })

    # Next glob all api files
    api_json_list = []
    api_regex = re.compile(r'([0-9]{5})-api-json-m([0-9.]+).csv')
    for a in glob.glob(f'{preds_dir}/*-api-json-*.csv'):
        file_name = os.path.basename(a)
        capture_group = api_regex.match(file_name)
        api_json_list.append({
            'order_id': capture_group.group(1),
            'API-JSON': capture_group.group(2)
        })

    # Next glob all api files
    api_df_list = []
    api_regex = re.compile(r'([0-9]{5})-api-df-m([0-9.]+).csv')
    for a in glob.glob(f'{preds_dir}/*-api-df-*.csv'):
        file_name = os.path.basename(a)
        capture_group = api_regex.match(file_name)
        api_df_list.append({
            'order_id': capture_group.group(1),
            'API-DF': capture_group.group(2)
        })

    assert len(mod_list) == len(api_json_list) == len(api_df_list), \
        'Unequal files scored by Module, JSON API and DataFrame API.'

    mod_df = pd.DataFrame(mod_list)
    api_json_df = pd.DataFrame(api_json_list)
    api_df_df = pd.DataFrame(api_df_list)

    df: pd.DataFrame = pd.merge(mod_df, api_df, how='inner', on='order_id')
    df.sort_values(by='order_id',inplace=True)
    df.reset_index(inplace=True)
    df.drop(columns=['index'], inplace=True)
    df['order_id'] = df['order_id'].astype(np.int16)
    df['Module'] = df['Module'].astype(np.float64)
    df['API'] = df['API'].astype(np.float64)
    df = pd.melt(df,
                 id_vars=['order_id'],
                 var_name='Method',
                 value_name='RMSE')

    # Create TS plots for each store id in a separate file
    register_matplotlib_converters()
    sns.set_context('notebook')

    sns.relplot(x='order_id',
                y='RMSE',
                hue='Method',
                kind='line',
                height=7,
                aspect=2,
                data=df).fig.savefig(f'{preds_dir}/metrics_plot.svg')




if __name__ == '__main__':
    # process the dataframe
    process()
