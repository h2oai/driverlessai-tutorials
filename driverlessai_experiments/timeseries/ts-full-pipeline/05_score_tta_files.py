import click
import glob
import importlib
import os


# import datetime as dt
# import numpy as np
import pandas as pd


@click.command()
@click.option('-n', '--name', 'experiment_name',
              required=True,
              help='Experiment name.')
@click.option('-t', '--test', 'test_ds_file', type=click.Path(exists=True,
                                                              file_okay=True,
                                                              dir_okay=False,
                                                              readable=True),
              required=True,
              help='Testing dataset CSV file path.')
def process(experiment_name,
            test_ds_file):
    """
    Score the TTA files in the 'score' directory, and create corresponding prediction files in the
    'predict/<experiment name> directory. Also calculate the metric (RMSE) to measure how good is the
    prediction for that file.

    :param experiment_name: Name of the experiment run
    :param test_ds_file: Path of the test dataset file used for RMSE calculation
    :return: None
    """
    # Note the shell wrapper ensures this python file is executed in the TTA scoring data directory.

    # print(experiment_name)
    # print(test_ds)

    # Get DAI scorer
    scorer = get_dai_scorer(experiment_name)

    # Load the test datasset
    # Read csv to data frame.
    test_ds = pd.read_csv(test_ds_file,
                          sep=',',
                          names=['Timeslot', 'StoreID', 'Product', 'Sale'],
                          parse_dates=['Timeslot'],
                          infer_datetime_format=True)

    # Glob all files to score, from the 'score' directory and then process each of them
    for file in glob.glob('score/*.csv'):
        score_ds = pd.read_csv(file)
        preds_ds = scorer.score_batch(score_ds)
        file_name = os.path.splitext(os.path.basename(file))[0]
        save_datasets(preds_ds,
                      f'predicted/{file_name}',
                      as_pickle=False,
                      as_csv=True)


def get_dai_scorer(experiment_name: str):
    """
    Import the Driverless AI scoring module dynamically based on the experiment name passed, and return
    the corresponding scorer object

    :param experiment_name: Name of DAI experiment for which to return the scoring object
    :return: A Scoring object of type scoring_h2oai_experiment_<experiment_name>.scorer.Scorer
    """
    scoring_module_name = 'scoring_h2oai_experiment_{}'.format(experiment_name)
    scoring_module = importlib.import_module(scoring_module_name)
    scoring_class = getattr(scoring_module, 'Scorer')

    scorer = scoring_class()
    return scorer


def save_datasets(df: pd.DataFrame,
                  filename: str,
                  as_pickle=True,
                  as_csv=True):
    """
    Saves the input dataframe as pickle and csv files, by default.

    :param df: The dataframe to save
    :param filename: File name to save as, output file will be filename.csv and filename.pickle
    :param as_pickle: Flag to save file as pickle, by default True
    :param as_csv: Flag to save file as csv, by default True
    :return: None
    """
    if as_pickle:
        df.to_pickle(filename+'.pickle')
    if as_csv:
        df.to_csv(filename+'.csv',
                  sep=",", header=True, index=False)


if __name__ == '__main__':
    # process the dataframe
    process()
