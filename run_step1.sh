#!/bin/bash
set -euo pipefail

code_dir="$(cd "$(dirname "$0")" && pwd)"
results_dir="$(cd "$code_dir/results" && pwd)"
matlab_bin="${WCOM_MATLAB:-/Applications/MATLAB_R2026a.app/bin/matlab}"
python_bin="$code_dir/.venv/bin/python"
export WCOM_MATLAB_CODE="$code_dir/MatLab_Codes"
export KERAS_BACKEND=tensorflow

cd "$results_dir"
"$matlab_bin" -batch "addpath(getenv('WCOM_MATLAB_CODE')); Main_Simulation; Process_Training_Data" > matlab-data.log 2>&1

run_case() (
    set -e
    local architecture="$1" snr_db="$2" snr_index="$3"
    local case_name="DNN${architecture}_${snr_db}dB"
    mkdir -p "$results_dir/cases/$case_name"
    cd "$results_dir/cases/$case_name"
    "$python_bin" -B -u "$code_dir/Python_Codes/LS_DNN_Training.py" \
        --architecture "$architecture" --snr-index "$snr_index" --data-dir "$results_dir" > training.log 2>&1
    "$python_bin" -B -u "$code_dir/Python_Codes/LS_DNN_Testing.py" \
        --snr-index "$snr_index" --data-dir "$results_dir" > testing.log 2>&1
)

# Run independent models concurrently. Each case has its own checkpoint and logs.
run_case 4 30 7 & p1=$!
run_case 1 30 7 & p2=$!
run_case 2 30 7 & p3=$!
run_case 3 30 7 & p4=$!
failed=0
for pid in "$p1" "$p2" "$p3" "$p4"; do
    wait "$pid" || failed=1
done
if (( failed )); then exit 1; fi

run_case 1 0 1 & p1=$!
run_case 1 10 3 & p2=$!
run_case 1 20 5 & p3=$!
run_case 1 50 8 & p4=$!
for pid in "$p1" "$p2" "$p3" "$p4"; do
    wait "$pid" || failed=1
done
if (( failed )); then exit 1; fi

"$matlab_bin" -batch "addpath(getenv('WCOM_MATLAB_CODE')); DNN_Results_Processing" > matlab-plots.log 2>&1
