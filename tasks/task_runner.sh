#!/usr/bin/env bash

set -e

force="false"

# Ensure working directory
cd "$(dirname "$0")"

# Load common functions
. task_common.sh

# TODO: Handle task errors

# TODO: Add verbose mode

archivist_start_tasks() {
    local runtime_start="$(date +%s)"
    local task_count=0

    while [ "$#" -ne 0 ]; do
        if [[ ! -d $1 ]] || [[ ! -f $1task.sh ]]; then
            shift
            continue
        fi

        # Load task opts
        . $1.config

        local run_time="$(date +%s)"
        local logged_check=($(archivist_parse_log $1$taskname.log check))
        local logged_time="${logged_check[1]}"
        local hours_interval="${task_opts[interval]}"

        local seconds_since=$((run_time-logged_time))
        local seconds_interval=$((hours_interval * 3600))

        if [[ "${task_opts[enabled]}" == "true" ]]; then
            if [[ "$force" == "true" ]] || [[ "$seconds_since" -gt "$seconds_interval" ]]; then
                bash -c "$1task.sh $task_count $#"
                ((task_count=task_count+1))
            fi
        fi
        shift
    done

    local runtime_end="$(date +%s)"
    archivist_echo "$task_count $((runtime_end-runtime_start))"
}

# Force flag
if [[ "$1" == force ]]; then
    force="true"
    shift
fi

# Task runner main
if [[ $# -gt 0 ]];then
    args=()
    for a in "$@"; do
        args+=("../tasks/$a/")
    done

    # TODO: This is ugly. Better way to quickly map args?

    archivist_start_tasks "${args[@]}"
else
    all_tasks=($(echo ../tasks/*/))
    if [[ ! "${all_tasks[@]}" == "../tasks/*/" ]];then
        archivist_start_tasks "${all_tasks[@]}"
    else
        archivist_echo "0 0"
        archivist_error "Error: No tasks!"
        exit 1
    fi
fi
