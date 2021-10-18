#!/usr/bin/env bash

VERSION="0.3.0a"
USAGE="$(cat << EOF
usage: archivist [add|list|set|remove|run] [options]
description: archivist.sh - Backup & track websites over time.

    example: add --task=my_website https://my_website.com

    -t, --task     - Select task
    -e, --enable   - Enable task
    -d, --disable  - Disable task
    -a, --accept   - Configure allowed files
    -x, --exclude  - Configure excluded paths
    -i, --interval - Configure task run interval in hours
    -r, --reject   - Configure rejected files
    --help, -h     - Display this message
    -v, --version  - Display version

EOF
)"

declare -A opts
opts[mode]="usage"
opts[enabled]=""
opts[accepts]=""
opts[rejects]=""
opts[excludes]=""
opts[interval]=""
opts[url]=""
opts[task]=""

# Ensure working directory
cd "$(dirname "$0")"

archivist_echo() {
    command printf %s\\n "$*" 2>/dev/null
}

archivist_error() {
    >&2 archivist_echo "$@"
}

archivist_has() {
    type "$1" > /dev/null 2>&1
}

archivist_get_checksum() {
    if archivist_has "sha1sum"; then
        archivist_echo "sha1sum"
    elif archivist_has "sha256sum"; then
        archivist_echo "sha256sum"
    elif archivist_has "shasum"; then
        archivist_echo "shasum"
    else
        archivist_error "Error: failed to find shasum!"
        exit 1
    fi
}

archivist_add_task() {
    local taskname="${opts[task]}"
    local taskdir="tasks/$taskname"
    local taskpath="$taskdir/task.sh"

    mkdir -p "$taskdir"

    if [[ -f "$taskpath" ]]; then
        archivist_error "Error: found task - \"$taskname\"!"
        exit 1
    fi

    archivist_echo '#!/usr/bin/env bash'                                    >> "$taskpath"
    archivist_echo ''                                                       >> "$taskpath"
    archivist_echo 'set -e'                                                 >> "$taskpath"
    archivist_echo ''                                                       >> "$taskpath"
    archivist_echo 'timestamp="$(date +%Y-%m-%d-%Hh-%Mm)"'                  >> "$taskpath"
    archivist_echo ''                                                       >> "$taskpath"
    archivist_echo '# Ensure working directory'                             >> "$taskpath"
    archivist_echo 'cd "$(dirname "$0")"'                                   >> "$taskpath"
    archivist_echo ''                                                       >> "$taskpath"
    archivist_echo '# Load common functions'                                >> "$taskpath"
    archivist_echo '. ../task_common.sh'                                    >> "$taskpath"
    archivist_echo '# Load webhook function'                                >> "$taskpath"
    archivist_echo '# . ../webhook.sh'                                      >> "$taskpath"
    archivist_echo '# Load options'                                         >> "$taskpath"
    archivist_echo '. .config'                                              >> "$taskpath"
    archivist_echo ''                                                       >> "$taskpath"

    # Write update
    archivist_echo 'archivist_update() {'                                   >> "$taskpath"
    archivist_echo "    local checksum=\"$(archivist_get_checksum)\""       >> "$taskpath"
    archivist_echo '    read -ra logged_update -d '\'\'' <<< "$(archivist_parse_log $taskname.log update)"' >> "$taskpath"
    archivist_echo '    local update_hashes="$(archivist_package $checksum $taskname-$timestamp)"' >> "$taskpath"
    archivist_echo '    if [[ ! "$update_hashes" == "${logged_update[@]:2}" ]]; then' >> "$taskpath"
    archivist_echo '        archivist_echo "[update]: $(date +%s) $update_hashes" >> "$taskname.log"' >> "$taskpath"
    archivist_echo '        archivist_echo "[check]: $(date +%s)" >> "$taskname.log"' >> "$taskpath"
    archivist_echo '        return 0'                                       >> "$taskpath"
    archivist_echo '    else'                                               >> "$taskpath"
    archivist_echo '        archivist_echo "[check]: $(date +%s)" >> "$taskname.log"' >> "$taskpath"
    archivist_echo '        return 1'                                       >> "$taskpath"
    archivist_echo '    fi'                                                 >> "$taskpath"
    archivist_echo '}'                                                      >> "$taskpath"
    archivist_echo ''                                                       >> "$taskpath"

    archivist_echo '# Task main'                                            >> "$taskpath"
    archivist_echo 'if [[ ! "${task_opts[enabled]}" == "false" ]]; then'    >> "$taskpath"
    archivist_echo '    archivist_download \'                               >> "$taskpath"
    archivist_echo '        && before "$@" \'                               >> "$taskpath"
    archivist_echo '        && archivist_update "$@" \'                     >> "$taskpath"
    archivist_echo '        && (archivist_release && after true "$@" && cleanup) \' >> "$taskpath"
    archivist_echo '        || after false "$@" && cleanup'                 >> "$taskpath"
    archivist_echo 'fi'                                                     >> "$taskpath"

    archivist_config_task
    chmod +x "$taskpath" "$taskdir/.config"

    archivist_echo "Added task - \"$taskname\"!"
}

archivist_remove_task() {
    if [[ -d tasks/$1 ]]; then
        rm -rf tasks/$1
        echo "Removed task - \"$1\""
    fi
}

archivist_merge_opts() {
    for i in "${!opts[@]}"; do
        if [[ "${opts[$i]}" == "" ]] && [[ ! "${task_opts[$i]}" == "" ]]; then
            opts[$i]="${task_opts[$i]}"
        fi
    done
}

archivist_config_task() {
    local config="tasks/${opts[task]}/.config"

    # Default values
    if [[ -z "${opts[enabled]}" ]]; then
        opts[enabled]="true"
    fi
    if [[ -z "${opts[interval]}" ]]; then
        opts[interval]="24"
    fi

    archivist_merge_opts
    archivist_echo '#!/usr/bin/env bash'                       >> "$config"
    archivist_echo ''                                          >> "$config"
    archivist_echo "taskname=\"${opts[task]}\""                >> "$config"
    archivist_echo ''                                          >> "$config"
    archivist_echo 'declare -A task_opts'                      >> "$config"
    archivist_echo "task_opts[enabled]=\"${opts[enabled]}\""   >> "$config"
    archivist_echo "task_opts[accepts]=\"${opts[accepts]}\""   >> "$config"
    archivist_echo "task_opts[rejects]=\"${opts[rejects]}\""   >> "$config"
    archivist_echo "task_opts[excludes]=\"${opts[excludes]}\"" >> "$config"
    archivist_echo "task_opts[interval]=\"${opts[interval]}\"" >> "$config"
    archivist_echo "task_opts[url]=\"${opts[url]}\""           >> "$config"
}

archivist_list_tasks() {
    readarray -d , -t tasks <<< "${opts[task]}"
    bash -c "./tasks/task_runner.sh list $(archivist_echo ${tasks[@]})"
}

archivist_run_tasks() {
    readarray -d , -t tasks <<< "${opts[task]}"

    local run_stats=($(./tasks/task_runner.sh force ${tasks[@]}))
    archivist_echo "Done! ran ${run_stats[0]} task(s) in ${run_stats[1]}(s)"
}

archivist_run() {
    case "${opts[mode]}" in
        add )
            if [[ -z "${opts[task]}" ]]; then
                archivist_error "Error: task name must be specified!"
                exit 1
            fi
            if wget -q --method=HEAD "${opts[url]}" 2>/dev/null; then
                archivist_add_task
            else
                archivist_error "Error: failed to contact url: \"${opts[url]}\"!"
                exit 1
            fi
        ;;

        list ) archivist_list_tasks ;;

        remove )
            if [[ -z "${opts[task]}" ]]; then
                archivist_error "Error: task name must be specified!"
                exit 1
            fi
            archivist_remove_task "${opts[task]}"
        ;;

        # TODO: Set multiple commands (a -t=task1,task2 -d) + check before load
        set )
            local taskname="${opts[task]}"
            if [[ -z "$taskname" ]]; then
                archivist_error "Error: task must be specified!"
                exit 1
            fi
            if [[ -z "${opts[enabled]}" ]] && [[ -z "${opts[interval]}" ]] && [[ -z "${opts[accepts]}" ]] && [[ -z "${opts[rejects]}" ]] && [[ -z "${opts[excludes]}" ]]; then
                archivist_error "Error: task options must be specified!"
                exit 1
            fi

            . "tasks/$taskname/.config" \
                && rm -f "tasks/$taskname/.config" \
                && archivist_config_task
        ;;

        usage ) archivist_echo "$USAGE" ;;

        run ) archivist_run_tasks ;;
    esac
}

archivist_process_params() {
    if ! archivist_has "wget"; then
        archivist_echo "Failed to find wget!"
        exit 1
    fi

    # Parse arguments
    while [ "$#" -ne 0 ]; do
        case "$1" in
            add ) opts[mode]="add" ;;
            list ) opts[mode]="list" ;;
            remove ) opts[mode]="remove" ;;
            run ) opts[mode]="run" ;;
            set ) opts[mode]="set" ;;
            http*://*.* ) opts[url]="$1" ;;
            -a=*|--accept=* ) opts[accepts]=${1#*=} ;;
            -e|--enable ) opts[enabled]="true" ;;
            -d|--disable ) opts[enabled]="false" ;;
            -x=*|--exclude=* ) opts[excludes]=${1#*=} ;;
            -r=*|--reject=* ) opts[rejects]=${1#*=} ;;
            -i=*|--interval=* ) opts[interval]=${1#*=} ;;
            -t=*|--task=* ) opts[task]=${1#*=} ;;
            --help|-h ) opts[mode]="usage" ;;
            -v|--version ) archivist_echo "v$VERSION"; return ;;
            * )
                archivist_error "Error: argument: \"$1\" is invalid!"
                exit 1
            ;;
        esac
        shift
    done
    archivist_run
}

archivist_process_params "$@"
