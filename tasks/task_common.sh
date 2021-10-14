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

# TODO: Loop over files, package small ones & shasum them all

archivist_package() {
    if [[ -d $2 ]]; then
        local package_entries=()
        local loop_entries=()
        local loop_hashes=()

        readarray -d $'\0' entries < <(find $2 -type f -print0)

        for e in "${entries[@]}"; do
            entry_size=$(wc -c <"$e")
            if [[ "$e" =~ .+\.(exe|pkg|deb|jar|tar|rar|gz|tgz|7z)$ ]] || [[ "$entry_size" -gt 10000000 ]] || [[ -x "$e" ]]; then
                entry_hash=($($1 "$e"))
                loop_entries+=($e)
                loop_hashes+=($entry_hash)

                cp $e .
            else
                package_entries+=($e)
            fi
        done

        if [[ "${#package_entries[@]}" -gt 0 ]]; then
            tar -czf $2.tar.gz "${package_entries[@]}"
            package_hash=($($1 $2.tar.gz))
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
        && mv *.{exe,pkg,dev,jar,rar,tar,gz,tgz,7z} "$releasedir" 2>/dev/null
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
    rm -rf $taskname-$timestamp.tar.gz $taskname-$timestamp *.{exe,pkg,dev,jar,rar,tar,tgz,7z}
}
