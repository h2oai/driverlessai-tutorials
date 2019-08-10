#!/usr/bin/env bash

# Commented. Enable for debugging
# set -x

current_dir="$(pwd)"
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
process_script="05_score_tta_files.py"
exp_data_dir_root="experiment_data"
tta_dir_prefix="tta-scoring-data"
use_pipeline="python"
use_method="module"

error_exit(){
    echo ""
    echo "$1" 1>&2
    echo ""
    exit 1
}

print_usage(){
    echo "Usage:"
    echo "  bash $0 -e <experiment run dir> -s <scoring data dir> [-p <python|mojo>] [-m <module|api|api2>] [-h | --help]"
    echo "Options:"
    echo "  -e <experiment run dir>     Experiment run directory containing scorer.zip. Will have same name as experiment in Driverless AI"
    echo "  -s <scoring data dir>       TTA scoring data directory created in step 04. Name will start with ${tta_dir_prefix}"
    echo "  -p <python|mojo>            Optional, defaults to python. Use Driverless AI Python or Mojo (Java) pipeline for scoring"
    echo "  -m <module|api|api2>        Optional, defaults to module. Score using python module in code or using HTTP JSON or DataFrame API endpoint"
    echo "  -h, --help                  Display usage information."
    echo "Details:"
    echo "  Scores the files in scoring data directory using the scoring pipeline for selected experiment. Also creates the necessary"
    echo "  environments with dependencies for the scoring pipeline to work."
    echo "  Scoring files will be picked from the 'score' sub-directory of selected scoring data directory."
    echo "  Output files will be generated in the 'predicted' sub-directory of selected scoring data directory."
    echo "  Scoring method 'api' sends the prediction dataframe as JSON to API server for batch scoring; 'api2' uses base64 encoded Pandas DataFrame"
}

parse_args_validate_then_exec(){
    # fail fast in case no parameters are passed
    [[ ! -z "${1}" ]] || { print_usage; error_exit "Expected parameters not passed during script invocation"; }
    while [[ "$1" != "" ]]; do
        case "$1" in
           -e )
                shift
                exp_run_dir="$1"
                # If directory exists, proceed; else print message and exit with error code
                [[ -d "${exp_run_dir}" ]] || { print_usage; error_exit "Experiment data directory ${script_dir}/${exp_run_dir} does not exist."; }
                [[ -f "${exp_run_dir}/experiment.json" ]] || { print_usage; error_exit "Experiment data directory ${script_dir}/${exp_run_dir} does not contain experiment.json file."; }
                [[ -f "${exp_run_dir}/experiment-config.json" ]] || { print_usage; error_exit "Experiment data directory ${script_dir}/${exp_run_dir} does not contain experiment-config.json."; }
                experiment_name=$(basename "${exp_run_dir}")
                ;;
           -s )
                shift
                scoring_data_dir="$1"
                # If directory exists, proceed; else print message and exit with error code
                [[ -d "${scoring_data_dir}/score" ]] || { print_usage; error_exit "Scoring data directory ${script_dir}/${scoring_data_dir}/score does not exist."; }
                files_to_score=$(ls "${scoring_data_dir}/score" | wc -l)
                [[ "${files_to_score}" -gt "0" ]] || { print_usage; error_exit "No files to score in scoring data directory ${script_dir}/${scoring_data_dir}/score."; }
                ;;
            -p )
                shift
                use_pipeline="$1"
                [[ "${use_pipeline}" =~ ^(python|mojo)$ ]] || { print_usage; error_exit "Incorrect pipeline option. Only 'python' and 'mojo' are supported."; }
                ;;
            -m )
                shift
                use_method="$1"
                [[ "${use_method}" =~ ^(module|api|api2)$ ]] || { print_usage; error_exit "Incorrect method option. Only 'module' and 'api' are supported."; }
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
    [[ ! -z "${exp_run_dir}" ]] || { print_usage; error_exit "Experiment run directory is mandatory"; }
    [[ ! -z "${scoring_data_dir}" ]] || { print_usage; error_exit "Scoring data directory is mandatory"; }

    # Check if experiment run dir has required pipeline.zip file based on the selected pipeline option
    case "${use_pipeline}" in
        python )
            [[ -f "${exp_run_dir}/scorer.zip" ]] || { print_usage; error_exit "Experiment data directory ${script_dir}/${exp_run_dir} does not contain python scoring pipeline scorer.zip."; }
            ;;
        mojo )
            [[ -f "${exp_run_dir}/mojo.zip" ]] || { print_usage; error_exit "Experiment data directory ${script_dir}/${exp_run_dir} does not contain mojo scoring pipeline mojo.zip."; }
            error_exit "Mojo pipeline option not yet supported for Test Time Augmentation scoring for Time Series experiments. Please use python type"
            ;;
        * )
            print_usage
            error_exit "Incorrect pipeline option, only 'python' and 'mojo' are supported"
            ;;
    esac

    # Check prediction duration to tta scoring data and experiment match.
    # Prediction duration in step 04 (TTA scoring file generation) should match the prediction duration used to create TTA data
    scoring_data_dir_base=$(basename "${scoring_data_dir}")
    scoring_data_dir_regex="tta-scoring-data-pd([0-9-]+)-rd([0-9-]+)"
    [[ "${scoring_data_dir_base}" =~ ${scoring_data_dir_regex} ]] || { error_exit "Scoring data directory ${scoring_data_dir_base} is not in the correct format."; }
    scoring_data_predict_duration=${BASH_REMATCH[1]}
    exp_config_predict_duration=$(cat "${exp_run_dir}/experiment-config.json" | grep -P -o '"num_prediction_periods": \K([0-9]+)')
    [[ "${scoring_data_predict_duration}" -eq "${exp_config_predict_duration}" ]] || { error_exit "Prediction duration mismatch. Experiment: ${exp_config_predict_duration}, Scoring Data: ${scoring_data_predict_duration}"; }

    # Check if predicted directory contains scored files
    if [[ -d "${scoring_data_dir}/predict/${experiment_name}" ]]; then
        files_scored=$(ls "${scoring_data_dir}/predict/${experiment_name}" | wc -l)
        [[ "${files_scored}" -gt "0" ]] || { print_usage; error_exit "Scored files already exist in directory ${script_dir}/${scoring_data_dir}/predict/${experiment_name}."; }
    fi

    # Check that experiment data dir is common for experiment and tta scoring data
    # Get experiment data directory;
    experiment_data_dir_regex="^([0-9a-z_/\-]+)/experiment_runs/.*"
    [[ "${exp_run_dir}" =~ ${experiment_data_dir_regex} ]] || { error_exit "Experiment run directory ${exp_run_dir} is not in the correct format."; }
    experiment_data_dir=${BASH_REMATCH[1]}
    # Get experiment data directory;
    score_experiment_data_dir_regex="^([0-9a-z_/\-]+)/tta-scoring-data.*"
    [[ "${scoring_data_dir}" =~ ${score_experiment_data_dir_regex} ]] || { error_exit "Scoring data directory ${scoring_data_dir} is not in the correct format."; }
    score_experiment_data_dir=${BASH_REMATCH[1]}
    # Esnure they are same
    [[ "${experiment_data_dir}" == "${score_experiment_data_dir}" ]] || { error_exit "Experiment Run and Scoring data do not have the same experiment data directory."; }


    # Create conda environment if it does not exist
    check_create_condaenv

    case "${use_method}" in
        module )
            score_tta_files_using_module
            ;;
        api )
            score_tta_files_using_api
            ;;
        api2 )
            score_tta_files_using_api2
            ;;
        * )
            print_usage
            error_exit "Incorrect method option, only 'module' and 'api' are supported"
            ;;
    esac

}

check_create_condaenv(){
    conda --version > /dev/null || error_exit "Conda required, please install miniconda or anaconada and configure PATH correctly."
    unzip -v > /dev/null || error_exit "Unzip required, please install unzip."
    # check if scoring-pipeline is already unzipped, if not unzip it
    [[ -d "${exp_run_dir}/scoring-pipeline" ]] || { pushd ${exp_run_dir} > /dev/null && unzip scorer.zip && popd > /dev/null; }
    conda_env_name=$(grep -P -o 'name: \K([a-z2_]+)' "${exp_run_dir}/scoring-pipeline/environment.yml")
    local env_count=$(conda env list | grep "${conda_env_name}" | wc -l)
    if [[ "${env_count}" == 0 ]]; then
        # create conda environment from the yml file
        [[ -e "${exp_run_dir}/scoring-pipeline/environment.yml" ]] || error_exit "Conda environment creation file not found"
        conda env create -f  "${exp_run_dir}/scoring-pipeline/environment.yml" || error_exit "Error creating conda environment"
        source activate "${conda_env_name}" &&
            conda install -y -c conda-forge click tqdm starlette uvicorn &&
            conda deactivate
    fi
}

score_tta_files_using_module(){
    # if control reaches here, then conda environment is available
    [[ -e "${process_script}" ]] || error_exit "Python script ${process_script} data not found"
    pushd "${scoring_data_dir}" > /dev/null &&
        source activate "${conda_env_name}" &&
        python "${script_dir}/${process_script}" -n "${experiment_name}" \
                                                 -t "${script_dir}/${experiment_data_dir}/test.pickle" \
                                                 -g "${script_dir}/${experiment_data_dir}/gap.pickle" \
                                                 --module &&
        conda deactivate &&
        rm -rf tmp &&
        popd > /dev/null
}

score_tta_files_using_api(){
    # if control reaches here, then conda environment is available
    [[ -e "${process_script}" ]] || error_exit "Python script ${process_script} data not found"
    pushd "${scoring_data_dir}" > /dev/null &&
        source activate "${conda_env_name}" &&
        (python  "${script_dir}/${exp_run_dir}/scoring-pipeline/http_server.py" --port=9090 > /dev/null 2>&1 &) &&
        sleep 20 &&
        python "${script_dir}/${process_script}" -n "${experiment_name}" \
                                                 -t "${script_dir}/${experiment_data_dir}/test.pickle" \
                                                 -g "${script_dir}/${experiment_data_dir}/gap.pickle" \
                                                 --api-json &&
        pkill -f http_server.py &&
        conda deactivate &&
        rm -rf tmp &&
        popd > /dev/null
}

score_tta_files_using_api2(){
    # if control reaches here, then conda environment is available
    [[ -e "${process_script}" ]] || error_exit "Python script ${process_script} data not found"
    pushd "${scoring_data_dir}" > /dev/null &&
        source activate "${conda_env_name}" &&
        (python  "${script_dir}/11_http_server2.py" -n ${experiment_name} -p 9090 > /dev/null 2>&1 &) &&
        sleep 20 &&
        python "${script_dir}/${process_script}" -n "${experiment_name}" \
                                                 -t "${script_dir}/${experiment_data_dir}/test.pickle" \
                                                 -g "${script_dir}/${experiment_data_dir}/gap.pickle" \
                                                 --api-df &&
        pkill -f 11_http_server2.py &&
        conda deactivate &&
        rm -rf tmp &&
        popd > /dev/null
}

main(){
    parse_args_validate_then_exec $@
}

main $@
