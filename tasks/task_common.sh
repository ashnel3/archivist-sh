#!/usr/bin/env bash

# TODO: Implement diffing

# TODO: Run custom scripts after task

archivist_echo() {
    command printf %s\\n "$*" 2>/dev/null
}

archivist_error() {
    >&2 archivist_echo "$@"
}

# TODO: Can this cope w/ larger files?

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
    if [[ -d $2 ]]; then
        local package_entries=()
        local loop_entries=()
        local loop_hashes=()

        mkdir -p release
        readarray -d $'\0' entries < <(cd $2 && find * -type f -print0)

        for e in "${entries[@]}"; do
            local entry_path="$2/$e"
            local entry_size=$(wc -c <"$entry_path")
            if [[ "$entry_path" =~ .+\.(exe|pkg|deb|jar|tar|rar|gz|tgz|7z)$ ]] || [[ "$entry_size" -gt 10000000 ]] || [[ -x "$entry_path" ]]; then
                local entry_hash=($($1 "$entry_path"))
                loop_entries+=("release/$entry_path")
                loop_hashes+=($entry_hash)
                mv $entry_path release
            else
                package_entries+=($e)
            fi
        done

        if [[ "${#package_entries[@]}" -gt 0 ]]; then
            tar -C $2 -czf release/$2.tar.gz "${package_entries[@]}"
            package_hash=($($1 release/$2.tar.gz))
            loop_hashes+=($package_hash)
        fi

        archivist_echo "${loop_hashes[@]}"
    else
        archivist_error "Error: Nothing downloaded..."
        exit 1
    fi
}

archivist_release() {
    local releasedir="../../release/$taskname-$timestamp"

    mkdir -p "$releasedir" 2>/dev/null \
        && mv release/* "$releasedir" 2>/dev/null
}

after() {
    [[ -x "./after.sh" ]] && ./after.sh "$@" 2>/dev/null
    return 0
}

before() {
    [[ -x "./before.sh" ]] && ./before.sh "$@" 2>/dev/null
    return 0
}

cleanup() {
    rm -rf release $taskname-$timestamp
}
