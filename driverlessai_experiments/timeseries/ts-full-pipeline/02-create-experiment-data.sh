#!/usr/bin/env bash

# Commented. Enable for debugging
# set -x

force_overwrite=false
current_dir="$(pwd)"
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
conda_env_name="ts-pipeline-env"
conda_env_def_file="environment.yml"
process_script="02_create_datasets.py"

error_exit(){
    echo ""
    echo "$1" 1>&2
    echo ""
    exit 1
}

print_usage(){
    echo "Usage:"
    echo "  bash $0 -i <fulldataset.pickle> -o <outdir> -s <train start time> -d <train duration> -g <gap> -f <forecast duration> [-h | --help]"
    echo "Options:"
    echo "  -i <fulldataset.pickle>     Full time series dataset, created by 01-generate-data script. Provide .pickle file"
    echo "  -o <outdir>                 Output directory name. Train and Test datasets will be created in this directory. Provide contextually logical name."
    echo "  -s <train start date>       Starting date for Train data YYYY-MM-DD format. Train dataset will start from 00:00:00.000 hours for that date."
    echo "  -d <train duration>         Training duration in days. Starting date is included in the duration."
    echo "  -g <gap duration>           Gap (in days) between last training date and first testing date."
    echo "  -f <forecast duration>      Duration (in days) for which we are forecasting. It starts from gap days after the last date in train dataset."
    echo "  -h, --help                  Display usage information."
    echo "Details:"
    echo "  Creates train (train.csv), test (test.csv) datasets in the output directory specified as <outdir>."
    echo "  Additionally a metadata file (metadata.json) will also be created that contains information about parameters"
    echo "  passed to this script to generate the data files"
}

check_or_download_tsimulus(){
    if [[ ! -e tsimulus-cli.jar ]]; then
        local latest_tag=$(curl --silent 'https://api.github.com/repos/cetic/tsimulus-cli/releases/latest' | grep -Po '"tag_name": "\K.*?(?=")')
        curl https://github.com/cetic/tsimulus-cli/releases/download/"${latest_tag}"/tsimulus-cli.jar --o tsimulus-cli.jar -silent
    fi
    # finally check that the file does exist, or error out
    [[ -e "tsimulus-cli.jar" ]] || error_exit "Error downloading TSimulus CLI. Cannot continue"
}

generate_ts_data(){
    # if flow reaches here, validation checks are assumed to be passed and output file is ok to overwrite if present
    java -jar tsimulus-cli.jar "${ts_def_file}" | tail -n +2 | sed -r 's/;/,/g' > "${tmp_csv_file}"
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
    [[ -e "${ts_process_script}" ]] || error_exit "Python script to process timeseries data not found"
    source activate "${conda_env_name}" &&
        python "${ts_process_script}" "${tmp_csv_file}" "${ts_out_file}" &&
        mv "${tmp_csv_file}" "${ts_out_file}.csv"
}

parse_args_then_exec(){
    # fail fast in case no parameters are passed
    [[ ! -z "${1}" ]] || { print_usage; error_exit "Expected parameters not passed during script invocation"; }
    while [[ "$1" != "" ]]; do
        case "$1" in
           -i )
                shift
                ts_full_data_file="$1"
                # error if such file does not exits
                [[ -e "${ts_full_data_file}" ]] || { print_usage; error_exit "Provided time series full data file does not exist."; }
                ;;
           -o )
                shift
                ts_out_file="$1"
                ;;
            -f | --force )
                force_overwrite=true
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

    # If required parame
    [[ ! -z "${ts_def_file}" ]] || { print_usage; error_exit "Timeseries definition file is mandatory"; }
    [[ ! -z "${ts_out_file}" ]] || { print_usage; error_exit "Timeseries output file is mandatory"; }

    # check if output file exist. If exists, and overwrite option is not specified then show error
    if [[ -e "${ts_out_file}.csv" || -e "${ts_out_file}.pickle" ]] && [[ "${force_overwrite}" == false ]]; then
        print_usage
        error_exit "Cannot overwite existing file. Use -f option"
    fi

    # check Java exists, if not exit with error
    java -version 2>/dev/null || error_exit "Java required. Please install java runtime"

    # check curl exists
    curl -V >/dev/null || error_exit "Curl required. Please install curl"

    # check tsimulus cli available, if not, download it
    check_or_download_tsimulus

    # generate Timeseries data based on the definition file
    generate_ts_data

    # Create conda environment if it does not exist
    check_create_condaenv

    # process the temp.csv file. Generate plots, save as feather for better read/write performance
    process_ts_file
}

main() {
    parse_args_then_exec $@
}

main $@