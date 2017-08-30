#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Removing previously generated files"
git clean -xfd ${DIR}/src

echo "Removing exising containers"
docker-compose -p magicsync -f ${DIR}/docker-compose.yml -f ${DIR}/docker-compose.development.yml down

echo "Launching containers"
docker-compose -p magicsync -f ${DIR}/docker-compose.yml -f ${DIR}/docker-compose.development.yml up -d --build

sleep 5

echo "Running compose on host"
which composer && composer --working-dir=${DIR}/src -vv install || exit 1

files_on_host_cmd="find ${DIR}/src -type f | wc -l"
files_in_container_cmd="docker exec magicsync_php_1 bash -c 'find /src/example/src -type f | wc -l'"

files_in_container_previous=$(eval $files_in_container_cmd)
sleep 2
files_in_container=$(eval $files_in_container_cmd)

while [ $files_in_container != $files_in_container_previous ]; do
    $files_in_container_previous=files_in_container
    files_in_container=$(eval $files_in_container_cmd)
    echo "Synced ${files_in_container} files..."
    sleep 1
done

files_on_host=$(eval $files_on_host_cmd)

echo "Checking generated files"
echo " - Files created in container: ${files_in_container}"
echo " - Files created on host: ${files_on_host}"
