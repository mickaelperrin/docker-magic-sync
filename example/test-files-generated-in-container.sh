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

echo "Launch our test, by running composer in container"
docker exec -u 33 -it magicsync_php_1 composer --working-dir=/src/example/src -vv install

while _has_new_files_on_host && [ $i -ne 2 ] ; do (( i++ )); done

_display_test_result

