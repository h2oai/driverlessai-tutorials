#!/usr/bin/env bash

# Commented. Enable for debugging
# set -x

current_dir="$(pwd)"
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
conda_env_name="ts-pipeline-env"
conda_env_def_file="environment.yml"
process_script="03_run_experiment.py"
exp_data_dir_root="experiment_data"
exp_run_dir_root="experiment_runs"
exp_accuracy=1
exp_time=1
exp_interpretability=8
exp_scorer="RMSE"
cur_date=$(date +%y%m%d)
temp_dir_name="run_${cur_date}_${BASHPID}"

error_exit(){
    echo ""
    echo "$1" 1>&2
    echo ""
    exit 1
}

print_usage(){
    echo "Usage:"
    echo "  bash $0 -d <experiment_data_dir> -c <experiment_config_file> [-t | --test]  [-h | --help]"
    echo "Options:"
    echo "  -d <experiment_data_dir>         Path (relative to this script) to the experiment data directory containing train.csv and test.csv files"
    echo "  -c <experiment_config_file>      Path (relative to this script) to the default experiment config settings. Dataset details not needed in file."
    echo "  -t, --test                       Include test dataset when executing the experiment (optional)."
    echo "  -h, --help                       Display usage information."
    echo "Details:"
    echo "  Executes an experiment on the Driverless AI server at DAI_HOST. The train dataset (train.csv) is obtained from "
    echo "  the experiment_data_dir. Experiment configuration is obtained from experiment_config_file. The dataset key information"
    echo "  in experiment_config_file can be left as it is. It will be obtained at runtime. "
    echo "  "
    echo "  The script expects below three environment variables to be set with Driverless AI connection information"
    echo "  - DAI_HOST - Url where DAI is running. Include full URL till the port e.g. http://localhost:12345"
    echo "  - DAI_USER - Username for connecting to Driverless AI"
    echo "  - DAI_PASS - Password for the above user"
    echo "  "
    echo "  If the experiment completes successfully; python and mojo scoring pipelines are downloaded for the experiment. "
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

run_experiment(){
    # Make the temporary directory for this experiment run
    mkdir -p "${exp_data_dir}/${exp_run_dir_root}/${temp_dir_name}" && echo "Created temporary directory ${exp_data_dir}/${exp_run_dir_root}/${temp_dir_name}"
    # pushd this directory
    # call python file. Pass DAI credentials. full path for train,test datasets and config file. aLso pass project name
    # read read experiment.json and get the experiment key
    # popd
    # rename the temporary directory to the experiment key
    # if control reaches here, then conda environment is available
    [[ -e "${process_script}" ]] || error_exit "Python script to generate experiment data not found"
    pushd "${exp_data_dir}/${exp_run_dir_root}/${temp_dir_name}" > /dev/null &&
        source activate "${conda_env_name}" &&
        python "${script_dir}/${process_script}" -h "${dai_host}" \
                                                 -u "${dai_user}" \
                                                 -p "${dai_pass}" \
                                                 -d "${script_dir}/${exp_data_dir}/train.csv" \
                                                 -c "${script_dir}/${exp_config_file}" \
                                                 -j "${project_name}" \
                                                 ${include_test_data:+ -t "${script_dir}/${exp_data_dir}/test.csv"} &&
        conda deactivate &&
        popd > /dev/null

        # remove temp directory if experiment.json does not exist.
        [[ -f "${exp_data_dir}/${exp_run_dir_root}/${temp_dir_name}/experiment.json" ]]  || { rm -rf "${exp_data_dir}/${exp_run_dir_root}/${temp_dir_name}"; }
}

parse_args_then_exec(){
    # fail fast in case no parameters are passed
    [[ ! -z "${1}" ]] || { print_usage; error_exit "Expected parameters not passed during script invocation"; }

    # fail fast if required environment variables are not defined; if defined get the values
    [[ ! -z "${DAI_HOST}" ]] || error_exit "Expected environment variable DAI_HOST is not defined."
    [[ ! -z "${DAI_USER}" ]] || error_exit "Expected environment variable DAI_USER is not defined."
    [[ ! -z "${DAI_PASS}" ]] || error_exit "Expected environment variable DAI_PASS is not defined."
    dai_host="${DAI_HOST}"
    dai_user="${DAI_USER}"
    dai_pass="${DAI_PASS}"


    while [[ "$1" != "" ]]; do
        case "$1" in
           -d )
                shift
                exp_data_dir="$1"
                # If directory exists, proceed; else print message and exit with error code
                [[ -d "${exp_data_dir}" ]] || { print_usage; error_exit "Experiment data directory ${script_dir}/${exp_data_dir} does not exist."; }
                [[ -f "${exp_data_dir}/train.csv" ]] || { print_usage; error_exit "Experiment data directory ${script_dir}/${exp_data_dir} does not contain train.csv dataset."; }
                ;;
           -c )
                shift
                exp_config_file="$1"
                # If directory exists, proceed; else print message and exit with error code
                [[ -f "${exp_config_file}" ]] || { print_usage; error_exit "Experiment configuration file ${script_dir}/${exp_config_file} does not exist."; }
                ;;
           -t | --test )
                include_test_data="yes"
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
    # check if needed parameters are provided
    [[ ! -z "${exp_data_dir}" ]] || { print_usage; error_exit "Experiment data directory is mandatory"; }
    [[ ! -z "${exp_config_file}" ]] || { print_usage; error_exit "Experiment config file is mandatory"; }

    # if test data is to be included check if file exists
    if [[ "${include_test_data}" == "yes" ]]; then
        [[ -f "${exp_data_dir}/test.csv" ]] || { print_usage; error_exit "Experiment data directory ${script_dir}/${exp_data_dir} does not contain test.csv dataset."; }
    fi

    # setup project_name from exp_data_dir
    project_name=$(basename ${exp_data_dir})

    # Create conda environment if it does not exist
    check_create_condaenv

    run_experiment
}

main() {
    parse_args_then_exec $@
}

main $@
