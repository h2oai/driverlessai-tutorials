import click
import random

import datetime as dt
import numpy as np
import pandas as pd
import seaborn as sns

from pandas.plotting import register_matplotlib_converters


@click.command()
@click.option('-i', '--input', 'input_pickle', type=click.Path(exists=True,
                                                               file_okay=True,
                                                               dir_okay=False,
                                                               readable=True),
              required=True,
              help='Full time series dataset pickle file from which to extract experiment data.')
@click.option('-s', '--start', 'train_start_date',
              required=True,
              type=click.DateTime(formats=['%Y-%m-%d']),
              help='Start date for training data.')
@click.option('-e', '--end', 'train_end_date',
              required=True,
              type=click.DateTime(formats=['%Y-%m-%d']),
              help='End date for training data.')
@click.option('-g', '--gap', 'gap_duration',
              required=True,
              type=click.INT,
              help='Gap (in days) between training and test data')
@click.option('-t', '--test', 'test_duration',
              required=True,
              type=click.INT,
              help='Duration (in days) for the testing dataset.')
@click.option('-m', '--missing', 'missing_data_percentage',
              default=0,
              required=False,
              type=click.INT,
              help='Proportion (in %) of missing data in train and test datasets. Optional, defaults to 0')
def process(input_pickle,
            train_start_date,
            train_end_date,
            gap_duration,
            test_duration,
            missing_data_percentage):
    """
    Creates train and test datasets (csv and pickle) in the output directory.
    Also creates timeseries plots for both the files.

    :param input_pickle: Full time series dataset pickle file from which to extract experiment data.
    :param train_start_date: Start date for training dataset
    :param train_end_date: End date for training datset
    :param gap_duration: Gap (in days) between training and testing dataset.
    :param test_duration: Duration (in days) of the testing dataset.
    :param missing_data_percentage: Proportion of missing data in train and test datasets. Optional, defaults to 0.
    :return: None
    """
    # Read the input data file
    df = pd.read_pickle(input_pickle)

    # Calculate data slice times
    train_end_date = train_end_date.replace(hour=23)
    test_start_date = train_end_date + dt.timedelta(days=gap_duration, hours=1)
    test_end_date = test_start_date + dt.timedelta(days=test_duration, hours=-1)

    # Slice data
    train_df = df[train_start_date:train_end_date].copy()
    test_df = df[test_start_date:test_end_date].copy()

    # Add missing data
    if missing_data_percentage != 0:
        create_missing_data(train_df, missing_data_percentage, 3)
        create_missing_data(test_df, missing_data_percentage, 3)

    # Plot train and test data
    create_plots(train_df, 'train')
    create_plots(test_df, 'test')

    # Save as CSV and pickle
    train_df.to_csv('train.csv'); train_df.to_pickle('train.pickle')
    test_df.to_csv('test.csv'); test_df.to_pickle('test.pickle')


def create_plots(data_frame,
                 filename_prefix):
    """
    Create timeseries plot for the passed dataframe

    :param data_frame: Input time series dataframe to plot
    :param filename_prefix: File name prefix. Generated file will be filename_prefix_plot.svg
    :return: None
    """
    sns.relplot(x='Timeslot',
                y='Sale',
                hue='StoreID',
                row='Product',
                kind='line',
                height=3,
                aspect=10,
                data=data_frame).fig.savefig(filename_prefix+'_plot.svg')


def create_missing_data(df,
                        missing_data_percentage,
                        target_col_index):
    """
    Creates missing data in the target column specified by the index (target_col_index).
    Proportion of rows for which missing data is created is determined by missing_data_percentage

    :param df: Input time series dataframe to inject NaN into.
    :param missing_data_percentage: Proportion of rows to mark as missing target data
    :param target_col_index: Index of the column (target) in which to create missing data
    :return: None
    """
    rows, _ = df.shape
    df.iloc[sorted(random.sample(range(rows), round(rows * missing_data_percentage/100))), target_col_index] = np.nan


if __name__ == '__main__':
    # Set sns and matplotlib options
    register_matplotlib_converters()
    sns.set_context('notebook')

    # process the dataframe
    process()
