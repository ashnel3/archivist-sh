#!/usr/bin/env bash

set -e

timestamp="$(date +%Y-%m-%d)"

# Ensure working directory
cd "$(dirname "$0")"

# Load common functions
. ../task_common.sh
# Load webhook function
# . ../webhook.sh
# Load options
. .config

archivist_update() {
    local checksum="sha1sum"
    read -ra logged_update -d '' <<< "$(archivist_parse_log $taskname.log update)"
    local update_hash="$(archivist_package $checksum $taskname-$timestamp)"
    if [[ ! "$update_hash" == "${logged_update[2]}" ]]; then
        archivist_echo "[update]: $(date +%s) $update_hash" >> "$taskname.log"
        archivist_echo "[check]: $(date +%s)" >> "$taskname.log"
        return 0
    else
        archivist_echo "[check]: $(date +%s)" >> "$taskname.log"
        return 1
    fi
}

before() {
    touch test_hooks
}

# Task main
if [[ ! "${task_opts[enabled]}" == "false" ]]; then
    archivist_download \
        && before "$@" \
        && archivist_update "$@" \
        && (archivist_release && after true "$@" && cleanup) \
        || after false "$@" && cleanup
fi
