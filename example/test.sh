#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Removing previously generated files"
git clean -xfd ${DIR}/src

echo "Removing exising containers"
docker-compose -p magicsync -f ${DIR}/docker-compose.yml -f ${DIR}/docker-compose.development.yml down

echo "Launching containers"
docker-compose -p magicsync -f ${DIR}/docker-compose.yml -f ${DIR}/docker-compose.development.yml up -d --build

sleep 5

echo "Running compose in container"
docker exec -it magicsync_php_1 composer --working-dir=/src/example/src -vv install

files_on_host_previous=$(find ${DIR}/src -type f | wc -l)
sleep 2
files_on_host=$(find ${DIR}/src -type f | wc -l)

files_in_container=$(docker exec magicsync_php_1 bash -c 'find /src/example/src -type f | wc -l')

while [ $files_on_host != $files_on_host_previous ]; do
    $files_on_host_previous=$files_on_host
    $files_on_host=$(find ${DIR}/src -type f | wc -l)
    echo "Synced ${files_on_host} files..."
    sleep 1
done

echo "Checking generated files"
echo " - Files created in container: ${files_in_container}"
echo " - Files created on host: ${files_on_host}"
