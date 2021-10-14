#!/usr/bin/env bats

load ./tasks/task_common.sh

@test "Parse log should parse logs" {
    run archivist_parse_log test/fixtures/testing.log update

    [ "$output" == "[update]: 1634103674 48f034ce9e0fad668b6405a0d7503701542b5851" ]
}
