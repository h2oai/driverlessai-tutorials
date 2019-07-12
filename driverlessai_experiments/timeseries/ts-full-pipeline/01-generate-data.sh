#!/usr/bin/env bash

# Commented. Enable for debugging
# set -x

force_overwrite=false
current_dir="$(pwd)"
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
conda_env_name="ts-pipeline-env"
conda_env_def_file="environment.yml"
ts_process_script="01_process_full_TS_csv.py"
tmp_csv_file="temp.csv"
fullts_data_directory="data_fullts"

error_exit(){
    echo ""
    echo "$1" 1>&2
    echo ""
    exit 1
}

print_usage(){
    echo "Usage:"
    echo "  bash $0 -d <tsdf.json> -o <output> [-f | --force] [-h | --help]"
    echo "Options:"
    echo "  -d <tsdf.json>            Timeseries definition file. Must be JSON file."
    echo "  -o <output>               Output file name. Will generate <output>.csv, <output>.pickle, and <output>.svg files in ${fullts_data_directory} directory"
    echo "  -f, --force               Force overwrite of output file."d sdfsdfsadfsdfsdf
    echo "  -h, --help                Display usage information."
    echo "Details:"
    echo "  Creates the master time series dataset for this pipeline demo. It simulates a larger database"
    echo "  from which section of data will be extracted to train and then predict on"
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
    java -jar tsimulus-cli.jar "${ts_def_file}" | tail -n +2 | sed -r 's/;/,/g' > "${fullts_data_directory}/${tmp_csv_file}"
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
    pushd "${fullts_data_directory}" > /dev/null &&
        source activate "${conda_env_name}" &&
        python "${script_dir}/${ts_process_script}" -i "${tmp_csv_file}" -o "${ts_out_file}"  &&
        mv "${tmp_csv_file}" "${ts_out_file}.csv" &&
        popd > /dev/null
}

parse_args_then_exec(){
    # fail fast in case no parameters are passed
    [[ ! -z "${1}" ]] || { print_usage; error_exit "Timeseries definition file is mandatory"; }
    while [[ "$1" != "" ]]; do
        case "$1" in
           -d )
                shift
                ts_def_file="$1"
                # error if such file does not exits
                [[ -e "${ts_def_file}" ]] || { print_usage; error_exit "Timeseries definition file does not exist"; }
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
    if [[ -e "${fullts_data_directory}/${ts_out_file}.csv" || -e "${fullts_data_directory}/${ts_out_file}.pickle" ]] && [[ "${force_overwrite}" == false ]]; then
        print_usage
        error_exit "Cannot overwite existing file. Use -f option"
    fi

    # Make fullts_data directory if it does not exists. if, exists do nothing
    mkdir -p "${fullts_data_directory}"

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