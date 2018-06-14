#!/usr/bin/env bash
set -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
i=0

. ${DIR}/test-utils.sh

_clean_test_directory
_remove_existing_test_containers
_build_and_start_test_containers

# Wait to ensure initial sync is performed
sleep 5

echo "Launch our test, by running composer on the host"
which composer && composer --working-dir=${DIR}/src -vv install || exit 1

while _has_new_files_in_container && [ $i -ne 500 ] ; do (( i++ )); done

_display_test_result


