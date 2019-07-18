#!/usr/bin/env bash

# Commented. Enable for debugging
# set -x

current_dir="$(pwd)"
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
conda_env_name="ts-pipeline-env"
conda_env_def_file="environment.yml"
process_script="02_extract_experiment_datasets.py"
exp_data_dir_root="experiment_data"
missing_data_percentage=0

error_exit(){
    echo ""
    echo "$1" 1>&2
    echo ""
    exit 1
}

print_usage(){
    echo "Usage:"
    echo "  bash $0 -i <dataset.pickle> -s <train start date> -e <train end date> -g <gap> -t <test duration> [-m <misssing data %> ] [-h | --help]"
    echo "Options:"
    echo "  -i <dataset.pickle>         Full time series dataset, created by 01-generate-data script. Provide .pickle file"
    echo "  -s <train start date>       Starting date for Train data YYYY-MM-DD format. Train dataset will start from 00:00:00.000 hours for that date."
    echo "  -e <train end date>         Ending date for Train data in YYYY-MM-DD format. Train dataset will include data for this date till 23:00:00 hours i.e. full 24 hour period."
    echo "  -g <gap duration>           Gap (in days) between last training date and first testing date."
    echo "  -t <test duration>          Duration (in days) for which we are generating test data. It starts from gap days after the last date in train dataset."
    echo "  -m <missing data %>         Proportion of target data that is missing in both Training and Test dataset. Optional, defaults to 0."
    echo "  -h, --help                  Display usage information."
    echo "Details:"
    echo "  Creates train and test datasets (csv and pickle) in the output directory. Also creates timeseries plots for both. "
    echo "  The output directory will be created in the format sYYYYMMDD-eYYYYMMDD-gdG-tdF-mMP, where"
    echo "  - sYYYYMMDD-eYYYYMMDD is the training dataset start and end date"
    echo "  - gdG is the gap duration"
    echo "  - tdF is the test duration"
    echo "  - mMP is proportion of missing data in Train and Test datasets"
    echo "  When the script is executed with certain inputs which results in an output directory that already exists, no action is taken."
}

check_create_condaenv(){
    conda --version > /dev/null || error_exit "Conda required, please install miniconda or anaconada and configure PATH correctly."
    local env_count=$(conda env list | grep "${conda_env_name}" | wc -l)
    if [[ "${env_count}" == 0 ]]; then
        # create conda environment from the yml file
        [[ -e "${conda_env_def_file}" ]] || error_exit "Conda environment creation file not found"
        conda env create -f "${conda_env_def_file}" || error_exit "Error creating conda environment"
    fi
}

process_ts_file(){
    # if control reaches here, then conda environment is available
    [[ -e "${process_script}" ]] || error_exit "Python script to generate experiment data not found"
    pushd "${exp_data_dir_root}/${exp_data_dir}" > /dev/null &&
        source activate "${conda_env_name}" &&
        python "${script_dir}/${process_script}" -i "${script_dir}/${ts_full_data_file}" \
                                                 -s "${formatted_start_date}" \
                                                 -e "${formatted_end_date}" \
                                                 -g "${gap_duration}" \
                                                 -t "${test_duration}" \
                                                 -m "${missing_data_percentage}" &&
        conda deactivate &&
        popd > /dev/null
}

parse_args_then_exec(){
    # fail fast in case no parameters are passed
    [[ ! -z "${1}" ]] || { print_usage; error_exit "Expected parameters not passed during script invocation"; }
    while [[ "$1" != "" ]]; do
        case "$1" in
           -i )
                shift
                ts_full_data_file="$1"
                # If file exists, proceed; else print message and exit with error code
                [[ -f "${ts_full_data_file}" ]] || { print_usage; error_exit "Provided time series full data file does not exist."; }
                ;;
           -s )
                shift
                start_date="$1"
                # convert input to expected date format and check with input. if they match, input is in expected format, so proceed ; else error
                formatted_start_date=$(date "+%F" -d "${start_date}" 2>/dev/null)
                [[ "${formatted_start_date}" == "${start_date}" ]] || { print_usage; error_exit "Invalid start date or date format. Use YYYY-MM-DD format."; }
                ;;
           -e )
                shift
                end_date="$1"
                # error is date is not in the valid format
                formatted_end_date=$(date "+%F" -d "${end_date}" 2>/dev/null)
                [[ "${formatted_end_date}" ==  "${end_date}" ]] || { print_usage; error_exit "Invalid end date or date format. Use YYYY-MM-DD format."; }
                ;;
           -g )
                shift
                gap_duration="$1"
                [[ "${gap_duration}" =~  ^[0-9]+$ ]] || { print_usage; error_exit "Gap duration (days) is expected to be an integer. If no gap is needed pass 0."; }
                ;;
           -t )
                shift
                test_duration="$1"
                # error is date is not in the valid format
                [[ "${test_duration}" =~  ^[1-9][0-9]*$ ]] || { print_usage; error_exit "Test data duration (days) is expected to be a non-zero integer."; }
                ;;
           -m )
                shift
                missing_data_percentage="$1"
                # error is date is not in the valid format
                [[ "${missing_data_percentage}" =~  ^[0-9]{1,2}$ ]] || { print_usage; error_exit "Proportion (%) of missing data to create in Train and Test datasets. Optional, defaults to 0."; }
                ;;
            -h | --help )
                print_usage
                exit 0
                ;;
            * )
                print_usage
                error_exit "Error: Incorrect parameters passed"
                ;;
        esac
        shift
    done

    # If required parameters are missing, print usage and exit
    [[ ! -z "${ts_full_data_file}" ]] || { print_usage; error_exit "Timeseries input data file is mandatory"; }
    [[ -f "${ts_full_data_file}" ]] || { print_usage; error_exit "Provided timeseries input data file is missing"; }
    [[ ! -z "${formatted_start_date}" ]] || { print_usage; error_exit "Training data start date is mandatory"; }
    [[ ! -z "${formatted_end_date}" ]] || { print_usage; error_exit "Training data end date is mandatory"; }
    [[ ! -z "${gap_duration}" ]] || { print_usage; error_exit "Gap duration is mandatory. If no gap, pass 0 as the value"; }
    [[ ! -z "${test_duration}" ]] || { print_usage; error_exit "Test data duration is mandatory"; }

    # Check if experiment data directory exists, if so dont proceed. If it does not exist, create it.
    exp_data_dir="s${formatted_start_date}-e${formatted_end_date}-gd${gap_duration}-td${test_duration}-m${missing_data_percentage}"
    [[ ! -d "${exp_data_dir_root}/${exp_data_dir}" ]] || error_exit "Experiment data directory ${exp_data_dir_root}/${exp_data_dir} already exists. No action taken."
    mkdir -p "${exp_data_dir_root}/${exp_data_dir}"

    # Create conda environment if it does not exist
    check_create_condaenv

    # process the temp.csv file. Generate plots, save as feather for better read/write performance
    process_ts_file
}

main() {
    parse_args_then_exec $@
}

main $@