import click

import datetime as dt
import numpy as np
import pandas as pd


@click.command()
@click.option('-o', '--outdir', 'tta_dir', type=click.Path(exists=True,
                                                           file_okay=False,
                                                           dir_okay=True,
                                                           readable=True,
                                                           writable=True),
              required=True,
              help='Output data directory where the TTA scoring files will be generated.')
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
@click.option('-p', '--predict', 'predict_duration',
              required=True,
              type=click.INT,
              help='Duration (in hours) of data to predict in each scoring data frame.')
@click.option('-r', '--roll', 'roll_duration',
              required=True,
              type=click.INT,
              help='Duration (in hours) by which to roll the data window for the next scoring cycle.')
def process(tta_dir,
            train_start_date,
            train_end_date,
            gap_duration,
            test_duration,
            predict_duration,
            roll_duration):
    """
    Creates TTA (test time augmentation) and rolling window based scoring dataframes from the test data
    in the output directory. These scoring files can then be passed to Driverless AI Scoring module for
    scoring.

    :param tta_dir: Output directory to create the TTA scoring data files.
    :param train_start_date: Start date for training dataset
    :param train_end_date: End date for training datset
    :param gap_duration: Gap (in days) between training and testing dataset.
    :param test_duration: Duration (in days) of the testing dataset.
    :param predict_duration: Duration (in hours) for which we are predicting in each scoring call.
    :param roll_duration: Duration (in hours) by which to roll the data window fo the next scoring call.
    :return: None
    """
    # Note the shell wrapper is taking care of changing to the appropriate data directory, so the train, gap and test
    # files will be in the current directory. The TTA file directory can be created here

    train_end_date = train_end_date.replace(hour=23)
    gap_start_date = train_end_date + dt.timedelta(hours=1)
    gap_end_date = gap_start_date + dt.timedelta(days=gap_duration, hours=-1)
    test_start_date = gap_end_date + dt.timedelta(hours=1)
    test_end_date = test_start_date + dt.timedelta(days=test_duration, hours=-1)

    rolling_slots = get_tta_scoring_slots(gap_start_date, gap_end_date,
                                          test_start_date, test_end_date,
                                          predict_duration, roll_duration)

    # Read the dataframes.
    df = pd.read_pickle('test.pickle')
    if gap_duration > 0:
        gap_df = pd.read_pickle('gap.pickle')
        df = pd.concat([gap_df, df])

    for slot in rolling_slots:
        tta_df = df[slot['tta_start']:slot['tta_end']].copy()
        score_df = df[slot['score_start']:slot['score_end']].copy()
        score_df['Sale'] = np.nan
        bind_df = pd.concat([tta_df, score_df])
        file_name = f"{slot['roll_counter_str']}-ss{slot['score_start']}-se{slot['score_end']}"
        save_datasets(bind_df,
                      tta_dir + "/score/" + file_name,
                      as_csv=True,
                      as_pickle=False)


#%% Define another function
def get_tta_scoring_slots(gs: dt.datetime,
                          ge: dt.datetime,
                          ts: dt.datetime,
                          te: dt.datetime,
                          pd: int,
                          rd: int):
    """
    Print the TTA scoring info in the following format
    TNNNN-ScoreTime-TTAstarttime-TTAendtime-PRDstarttime-PRDendtime
    :param gs: Gap start
    :param ge: Gap end
    :param ts: Test Start
    :param te: Test end
    :param pd: Predict Duration (hours) should be > 0
    :param rd: Roll Duration (hours) should be > 0
    :return: List of dicts containing the tta slot information
    """
    slots_list = []
    if ge > gs:
        tta_start = gs
    else:
        tta_start = ts
    score_pointer = ts
    roll_counter = 0
    while score_pointer <= te - dt.timedelta(hours=pd-1):
        tta_end = tta_start + dt.timedelta(hours=(roll_counter-1)*rd)
        score_start = score_pointer
        score_end = score_pointer + dt.timedelta(hours=pd-1)
        d = {
            'roll_counter': roll_counter,
            'roll_counter_str': f"{roll_counter:05d}",
            'tta_start': tta_start,
            'tta_end': tta_end,
            'score_start': score_start,
            'score_end': score_end
        }
        slots_list.append(d)
        score_pointer = score_pointer + dt.timedelta(hours=rd)
        roll_counter = roll_counter + 1
    return slots_list


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
    # Set sns and matplotlib options

    # process the dataframe
    process()
