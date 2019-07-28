#!/usr/bin/env bash

# Commented. Enable for debugging
# set -x

current_dir="$(pwd)"
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
conda_env_name="ts-pipeline-env"
conda_env_def_file="environment.yml"
process_script="04_generate_tta_files.py"
exp_data_dir_root="experiment_data"
exp_data_dir_regex="s([0-9-]+)-e([0-9-]+)-gd([0-9]+)-td([0-9]+)-m[0-9]+"
tta_dir_prefix="tta-scoring-data"
predict_duration=24  # daily
roll_duration=1  # hourly

error_exit(){
    echo ""
    echo "$1" 1>&2
    echo ""
    exit 1
}

print_usage(){
    echo "Usage:"
    echo "  bash $0 -i <experiment data dir> [-p <prediction duration> ] [-r <roll duration>] [-h | --help]"
    echo "Options:"
    echo "  -i <experiment data dir>    Experiment data directory containing train, gap, and test csv and pickle files"
    echo "  -p <predict duration>       Duration (in hours) of data to predict in each scoring data frame. Optional, defaults to 24 hours i.e 1 day"
    echo "  -r <roll duration>          Duration (in hours) by which to roll the data window and score for next predict duration. Optional, defaults to 1 hour"
    echo "  -h, --help                  Display usage information."
    echo "Details:"
    echo "  Creates TTA and rolling window based scoring dataframes (csv and pickle) in the output directory."
    echo "  The output directory will be created in the format tta-scoring-data-pdP-rdR, where"
    echo "  - pdP is the predict duration"
    echo "  - rdR is the rolling duration"
    echo "  The output directory will be created as a subdirectory of <experiment data directory>"
    echo "  When the script is executed with certain inputs which results in an output directory that already exists, no action is taken."
}

parse_args_then_exec(){
    # fail fast in case no parameters are passed
    [[ ! -z "${1}" ]] || { print_usage; error_exit "Expected parameters not passed during script invocation"; }
    while [[ "$1" != "" ]]; do
        case "$1" in
           -i )
                shift
                exp_data_dir="$1"
                # If directory exists, proceed; else print message and exit with error code
                [[ -d "${exp_data_dir}" ]] || { print_usage; error_exit "Experiment data directory ${script_dir}/${exp_data_dir} does not exist."; }
                [[ -f "${exp_data_dir}/train.pickle" ]] || { print_usage; error_exit "Experiment data directory ${script_dir}/${exp_data_dir} does not contain train.pickle dataset."; }
                [[ -f "${exp_data_dir}/test.pickle" ]] || { print_usage; error_exit "Experiment data directory ${script_dir}/${exp_data_dir} does not contain test.pickle dataset."; }
                ;;
           -p )
                shift
                predict_duration="$1"
                # error is date is not in the valid format
                [[ "${predict_duration}" =~  ^[1-9][0-9]*$ ]] || { print_usage; error_exit "Predict duration (hours) is expected to be a non-zero integer."; }
                ;;
           -r )
                shift
                roll_duration="$1"
                # error is date is not in the valid format
                [[ "${roll_duration}" =~  ^[1-9][0-9]*$ ]] || { print_usage; error_exit "Roll duration (hours) is expected to be a non-zero integer."; }
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
    [[ ! -z "${exp_data_dir}" ]] || { print_usage; error_exit "Experiment data directory is mandatory"; }

    # Check if experiment data directory is in the correct format
    exp_data_dir_base=$(basename ${exp_data_dir})
    [[ ${exp_data_dir_base} =~ ${exp_data_dir_regex} ]] || { error_exit "Experiment data directory ${exp_data_dir_base} is not in the correct format."; }

    # Extract information from data directory name
    start_date=${BASH_REMATCH[1]}
    end_date=${BASH_REMATCH[2]}
    gap_duration=${BASH_REMATCH[3]}
    test_duration=${BASH_REMATCH[4]}

    # Generate tta directory
    tta_dir="${tta_dir_prefix}-pd${predict_duration}-rd${roll_duration}"
    [[ ! -d "${exp_data_dir_root}/${exp_data_dir_base}/${tta_dir}" ]] || error_exit "TTA data directory ${exp_data_dir_root}/${exp_data_dir}/${tta_dir} already exists. No action taken."
    mkdir -p "${exp_data_dir_root}/${exp_data_dir_base}/${tta_dir}/score"
    mkdir -p "${exp_data_dir_root}/${exp_data_dir_base}/${tta_dir}/predicted"

    # Create conda environment if it does not exist
    check_create_condaenv

    generate_tta_scoring_files
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

generate_tta_scoring_files(){
    # if control reaches here, then conda environment is available
    [[ -e "${process_script}" ]] || error_exit "Python script to generate experiment data not found"
    pushd "${exp_data_dir_root}/${exp_data_dir_base}" > /dev/null &&
        source activate "${conda_env_name}" &&
        python "${script_dir}/${process_script}" -o "${tta_dir}" \
                                                 -s "${start_date}" \
                                                 -e "${end_date}" \
                                                 -g "${gap_duration}" \
                                                 -t "${test_duration}" \
                                                 -p "${predict_duration}" \
                                                 -r "${roll_duration}" &&
        conda deactivate &&
        popd > /dev/null
}

main() {
    parse_args_then_exec $@
}

main $@