#!/usr/bin/env bash

set -o pipefail
set -ex

MOJO_FILE="${1:-pipeline.mojo}"
CSV_FILE="${2:-example.csv}"
LICENSE_FILE="${3}"
CMD_LINE="java -Xmx5g -Dai.h2o.mojos.runtime.license.file=${LICENSE_FILE} -cp mojo2-runtime.jar ai.h2o.mojos.ExecuteMojo"

cat <<EOF >&2
======================
Running MOJO2 example
======================

MOJO file    : ${MOJO_FILE}
Input file   : ${CSV_FILE}

Command line : ${CMD_LINE} ${MOJO_FILE} ${CSV_FILE}

EOF

${CMD_LINE} ${MOJO_FILE} ${CSV_FILE}

