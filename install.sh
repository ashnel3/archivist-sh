#!/usr/bin/env bash

# TODO: Installer

if [[ ! "$1" == "-y" ]]; then
    read -p "This script will install archivist globally & create a scheduled task. Continue? (y/n): " -n 1 -r ans
    echo ""
fi
