#!/usr/bin/env bats

@test "Archivist should be executable" {
    [ -x './archivist' ]
    [ -x './archivist.sh' ]
}

@test "Initializing w/o arguments should print usage" {
    run ./archivist

    [ "$status" -eq 0 ]
    [ "${lines[0]}" == "usage: archivist [add|set|remove|run] [options]" ]
}

@test "Arguments shouldn't eat eachother" {
    run ./archivist -t= --help

    [ "$status" -eq 0 ]
    [ "${lines[0]}" == "usage: archivist [add|set|remove|run] [options]" ]
}

@test "Add should generate task & output correctly" {
    run ./archivist add -t=test_run https://example.com

    [ "$status" -eq 0 ]
    [ "$output" == 'Added task - "test_run"!' ]
    [ -f "tasks/test_run/task.sh" ]
}

@test "Add should configure task" {
    run ./archivist add -t=test_config -i=3 -a="html,php" https://example.com
    mapfile -t clines < tasks/test_config/.config

    [ "$status" -eq 0 ]
    [ "$(printf ${clines[2]})" == "taskname=\"test_config\"" ]
    [ "$(printf ${clines[6]})" == "task_opts[accepts]=\"html,php\"" ]
}

@test "Add should fail if URL doesn't exist" {
    run ./archivist add -t=test_bad_url https://exampleeeee.coms

    [ "$status" -eq 1 ]
}

@test "Add should fail if task already exists" {
    ./archivist add -t=test_dup https://example.com > /dev/null
    run ./archivist add -t=test_dup https://example.com

    [ "$status" -eq 1 ]
    [ "${lines[0]}" == 'Error: found task - "test_dup"!' ]
}

@test "Remove should delete task & output correctly" {
    ./archivist add -t=test_delete https://example.com > /dev/null
    run ./archivist remove -t=test_delete

    [ "$status" -eq 0 ]
    [ ! -f "tasks/test_delete/task.sh" ]
    [ "$output" == 'Removed task - "test_delete"' ]
}

@test "Run should generate log & release" {
    ./archivist add -t=test_files https://example.com
    run ./archivist run

    [ "$status" -eq 0 ]
    [ -f tasks/test_files/test_files.log ]
    [ -f release/test_files/*.tar.gz ]
}

@test "Set should configure task & output correctly" {
    ./archivist add -t=test_set -a="xml,json" https://example.com > /dev/null
    run ./archivist set -t=test_set -a="xml,json"
    readarray -t clines < tasks/test_set/.config

    [ "$status" -eq 0 ]
    [ "$(printf ${clines[6]})" == "task_opts[accepts]=\"xml,json\"" ]
    [ "$(printf ${clines[9]})" == "task_opts[interval]=\"3\"" ]
}

@test "Set should disable task" {
    ./archivist add -t=test_disable https://example.com
    run ./archivist set -t=test_disable -d
    readarray -t clines < tasks/test_disable/.config

    [ "$status" -eq 0 ]
    [ "$(printf ${clines[5]})" == 'task_opts[enabled]="false"' ]
}

@test "Set w/o options should fail" {
    run ./archivist set -t=test_run

    [ "$status" -eq 1 ]
}
