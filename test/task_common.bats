#!/usr/bin/env bats

load ./tasks/task_common.sh

@test "Parse log should parse logs" {
    run archivist_parse_log test/fixtures/testing_log update

    [ "$output" == "[update]: 9 e7" ]
}
