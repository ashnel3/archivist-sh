#!/usr/bin/env bash

# TODO: Implement diffing

# TODO: Run custom scripts after task

archivist_echo() {
    command printf %s\\n "$*" 2>/dev/null
}

archivist_error() {
    >&2 archivist_echo "$@"
}

archivist_parse_log() {
    if [[ ! -f "$1" ]]; then
        return 0
    fi

    tac "$1" | while read l; do
        if [[ $l == \[$2\]:* ]]; then
            archivist_echo "$l"
            return 0
        fi
    done
}

# TODO: Detect and reject dynamic files

archivist_download() {
    wget_args=(
        -r
        -A "${task_opts[accepts]}"
        -R "${task_opts[rejects]}"
        -P "./$taskname-$timestamp"
    )

    # Limit recursion if excludes is *
    if [[ "${task_opts[excludes]}" == "*" ]]; then
        wget_args+=(-l 1)
    else
        wget_args+=(-X "${task_opts[excludes]}")
    fi

    wget -q -N -k -np -nd "${wget_args[@]}" "${task_opts[url]}"
}

archivist_diff() {
    return 0
}

archivist_package() {
    if [[ -d $1 ]]; then
        (cd $1 && tar -czf "../$1.tar.gz" *)
    else
        archivist_error "Nothing downloaded..."
    fi
}

archivist_release() {
    local releasedir="../../release/$taskname"

    mkdir -p "$releasedir" \
        && mv *.tar.gz "$releasedir"
}

after() {
    return 0
}

before() {
    return 0
}

cleanup() {
    rm -rf $taskname-$timestamp.tar.gz $taskname-$timestamp
}
