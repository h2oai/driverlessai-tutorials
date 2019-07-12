import click
import numpy as np
import pandas as pd
import seaborn as sns

from pandas.plotting import register_matplotlib_converters


@click.command()
@click.option('-i', '--input', 'in_file', type=click.Path(exists=True), help='Input time series data file (csv)')
@click.option('-o', '--output', 'output', type=click.STRING, help='Output file prefix.')
def process(in_file, output):
    """
    Process a time series file, create a plot, save the data as pickle.

    This function processes the time series csv file, provided as input.
    Creates a plot of the time series and saves it as output_plot.svg.
    It also converts the input csv file and stores it as output.pickle for faster processing.
    """
    # Read csv to data frame.
    df = pd.read_csv(in_file,
                     sep=',',
                     header=0,
                     names=['Timeslot', 'StoreID', 'Product', 'Sale'],
                     parse_dates=['Timeslot'],
                     infer_datetime_format=True)

    # Round Sale and convert from float to int64
    df['Sale'] = pd.Series.round(df['Sale']).apply(np.int64)
    df['StoreID'] = df['StoreID'].astype('category')
    df['Product'] = df['Product'].astype('category')

    # Set dataframe index to help easy slicing
    df.set_index('Timeslot', drop=False, inplace=True)

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
