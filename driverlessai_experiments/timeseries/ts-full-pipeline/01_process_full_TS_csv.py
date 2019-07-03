import click
import numpy as np
import pandas as pd
import seaborn as sns

from pandas.plotting import register_matplotlib_converters

@click.command()
@click.argument('input', type=click.Path(exists=True))
@click.argument('output', type=click.Path(exists=False))
def process(input, output):
    """
    Process a time series file, create a plot, save the data as feather.

    This function processes the time series cav file, provided as INPUT.
    Creates a plot of the time series, and then saves the file as OUTPUT
    in the pickle format.

    :param input: The input CSV file.
    :param output: The output file name, will result in output.pickle file
    :return: None
    """
    # Read csv to data frame.
    df = pd.read_csv(input,
                     sep=',',
                     header=0,
                     names=['Timeslot', 'StoreID', 'Product', 'Sale'],
                     parse_dates=['Timeslot'],
                     infer_datetime_format=True)

    # Round Sale and convert from float to int64
    df['Sale'] = pd.Series.round(df['Sale']).apply(np.int64)
    df['StoreID'] = df['StoreID'].astype('category')
    df['Product'] = df['Product'].astype('category')


    # Create TS plots for each store id in a separate file
    register_matplotlib_converters()
    sns.set_context('notebook')

    sns.relplot(x='Timeslot',
                y='Sale',
                hue='StoreID',
                row='Product',
                kind='line',
                height=3,
                aspect=10,
                data=df).fig.savefig(output+'_plot.svg')

    # Store the file as pickle
    df.to_pickle(output+'.pickle')


if __name__ == '__main__':
    process()