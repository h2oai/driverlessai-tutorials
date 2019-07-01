#!/usr/bin/env bash

# Commented. Enable for debugging
# set -x

force_overwrite=false
current_dir="$(pwd)"
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

error_exit(){
    echo ""
    echo "$1" 1>&2
    echo ""
    exit 1
}

print_usage(){
    echo "Usage:"
    echo "  bash $0 -d <tsdf.json> -o <output.csv> [-f | --force] [-h | --help]"
    echo "Options:"
    echo "  -d <tsdf.json>            Timeseries definition file. Must be JSON file."
    echo "  -o <output.csv>           Output file. Must be CSV."
    echo "  -f, --force               Force overwrite of output file."
    echo "  -h, --help                Display usage information."
    echo "Details:"
    echo "  Creates the master time series dataset for this pipeline demo. It simulates a larger database"
    echo "  from which section of data will be extracted to train and then predict on"
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
    if [[ -e "${ts_out_file}" && "${force_overwrite}" == false ]]; then
        print_usage
        error_exit "Cannot overwite existing file. Use -f option"
    fi

    # check Java exists, if not exit with error
    java -version 2>/dev/null || error_exit "Java required. Please install java runtime"

    # check curl exists
    curl -V >/dev/null || error_exit "Curl required. Please install curl"

    # check tsimulus cli available, if not, download it
    check_or_download_tsimulus

    generate_ts_data


}

check_or_download_tsimulus(){
    if [[ ! -e tsimulus-cli.jar ]]; then
        local latest_tag=$(curl --silent 'https://api.github.com/repos/cetic/tsimulus-cli/releases/latest' | grep -Po '"tag_name": "\K.*?(?=")')a
        curl https://github.com/cetic/tsimulus-cli/releases/download/"${latest_tag}"/tsimulus-cli.jar --o tsimulus-cli.jar -silent
    fi
    # finally check that the file does exist, or error out
    [[ -e "tsimulus-cli.jar" ]] || error_exit "Error downloading TSimulus CLI. Cannot continue"
}

generate_ts_data(){
    # if flow reaches here, validation checks are assumed to be passed and output file is ok to overwrite if present
    java -jar tsimulus-cli.jar "${ts_def_file}" | tail -n +2 | sed -r 's/;/,/g' > temp.csv
}

main() {
    parse_args_then_exec $@
}

main $@