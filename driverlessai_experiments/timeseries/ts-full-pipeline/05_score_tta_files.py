import click
import glob
import importlib
import os
import re


import datetime as dt
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
@click.option('-g', '--gap', 'gap_ds_file', type=click.Path(exists=False,
                                                            file_okay=True,
                                                            dir_okay=False,
                                                            readable=True),
              required=False,
              help='Gap dataset CSV file path.')
def process(experiment_name,
            test_ds_file,
            gap_ds_file):
    """
    Score the TTA files in the 'score' directory, and create corresponding prediction files in the
    'predict/<experiment name> directory. Also calculate the metric (RMSE) to measure how good is the
    prediction for that file.

    :param experiment_name: Name of the experiment run
    :param test_ds_file: Path of the test dataset file used for RMSE calculation
    :param gap_ds_file: Path of the gap dataset file used for RMSE calculation
    :return: None
    """
    # Note the shell wrapper ensures this python file is executed in the TTA scoring data directory.

    # print(experiment_name)
    # print(test_ds)

    # Get DAI scorer
    scorer = get_dai_scorer(experiment_name)

    # Load the test datasset
    # Read csv to data frame.
    # test_ds = pd.read_csv(test_ds_file,
    #                       sep=',',
    #                       names=['Timeslot', 'StoreID', 'Product', 'Sale'],
    #                       parse_dates=['Timeslot'],
    #                       infer_datetime_format=True)
    test_ds = pd.read_pickle(test_ds_file)
    if gap_ds_file is not None and os.path.exists(gap_ds_file):
        gap_ds = pd.read_pickle(gap_ds_file)
        test_ds = pd.concat(gap_ds, test_ds)

    # Create the output directory if it does not exists
    os.makedirs(f'predicted/{experiment_name}', exist_ok=True)

    # Compile the regex
    regex = re.compile(r'([0-9]{5})-ss([0-9 -:]{19})-se([0-9 -:]{19})')

    # Glob all files to score, from the 'score' directory and then process each of them
    for file in glob.glob('score/*.csv'):
        # Extract scoring duration from the file name. Calculate how many data points it makes
        # Per hour is 8 data points
        file_name = os.path.splitext(os.path.basename(file))[0]
        capture_groups = regex.match(file_name)
        file_order = capture_groups.group(1)
        score_start_time = dt.datetime.strptime(capture_groups.group(2), r'%Y-%m-%d %H:%M:%S')
        score_end_time = dt.datetime.strptime(capture_groups.group(3), r'%Y-%m-%d %H:%M:%S')
        last_n_values = (((score_end_time - score_start_time).seconds // 3600) + 1) * 8

        # Load dataset to score and score it
        score_ds = pd.read_csv(file)
        preds_ds = scorer.score_batch(score_ds)
        preds_ds.columns = ['Sale_hat']
        preds_ds = pd.concat([score_ds, preds_ds], axis=1)

        # Get actual and predicted value arrays.
        # Actuals are obtained from test data using score start and end time to slice
        # Predicted data frame even predicts and returns TTA data. So use last_n_values to slice it
        actual_values = test_ds.loc[score_start_time:score_end_time, 'Sale'].values
        predicted_values = preds_ds['Sale_hat'].values[-last_n_values:]

        # Ensure the arrays match
        assert len(actual_values) == len(predicted_values)
        df = pd.DataFrame({'actual': actual_values, 'predicted': predicted_values})
        # Note that we drop the rows in case there is an NaN in actuals to calculate RMSE
        df.dropna(inplace=True)
        rmse = ((df['predicted'] - df['actual']) ** 2).mean() ** 0.5

        # Save the predictions
        save_datasets(preds_ds,
                      f'predicted/{experiment_name}/{file_order}-m{rmse}',
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
