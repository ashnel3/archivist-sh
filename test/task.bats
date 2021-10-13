#!/usr/bin/env bats

load ./tasks/task_common.sh

@test "Task should run hooks" {
    cp -r test/fixtures/test_hooks/ tasks/
    ./archivist run

    [ -f "./tasks/test_hooks/test_hooks" ]
}

@test "Task should run before & after scripts" {
    taskdir="./tasks/test_scripts"
    after="$taskdir/after.sh"
    before="$taskdir/before.sh"

    ./archivist add -t=test_scripts https://example.com > /dev/null
    archivist_echo '#!/usr/bin/env bash'  >> "$before"
    archivist_echo ''                     >> "$before"
    archivist_echo 'touch test_before'    >> "$before"

    archivist_echo '#!/usr/bin/env bash'  >> "$after"
    archivist_echo ''                     >> "$after"
    archivist_echo 'touch test_after'     >> "$after"
    chmod +x $after $before

    ./archivist run

    [ -f "./tasks/test_scripts/test_before" ]
    [ -f "./tasks/test_scripts/test_after" ]
}
