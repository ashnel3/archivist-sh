#!/usr/bin/env bats

@test "Task runner should run single tasks" {
    ./archivist add -t=test_single https://example.com > /dev/null
    stats_arr=($(./tasks/task_runner.sh force test_single))

    [ "${stats_arr[0]}" -eq 1 ]
}

@test "Task runner should run multiple tasks & ignore disabled" {
    rm -rf ./tasks/test_* \
        && ./archivist add -t=test_m1 https://example.com > /dev/null \
        && ./archivist add -t=test_m2 https://example.com > /dev/null \
        && ./archivist add -t=test_m3 https://example.com > /dev/null \
        && ./archivist set -t=test_m3 -d > /dev/null
    stats_arr=($(./tasks/task_runner.sh force test_m1 test_m2 test_m3))

    [ "${stats_arr[0]}" -eq 2 ]
}

@test "Task runner should run tasks & return stats array" {
    ./archivist add -t=test_1 https://example.com > /dev/null
    run ./tasks/task_runner.sh force
    stats_arr=($output)

    [ "$status" -eq 0 ]
    [ "${#stats_arr[@]}" -gt 0 ]
}

@test "Task runner should fail w/o tasks" {
    rm -rf ./tasks/test_*
    [ "$(./tasks/task_runner.sh 2>&1 > /dev/null)" == 'Error: No tasks!' ]
}
