#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Display the files on host
# - excluding temporary .unison files
function _files_on_host() {
  find ${DIR}/src -print | sed "s~${DIR}~~g"
}
function _files_on_host_without_unison_tpm_files() {
  find ${DIR}/src -type d -name ".unison*" -prune -o -print | sed "s~${DIR}~~g"
}

# Count numbber of files on host
function _count_files_on_host() {
  _files_on_host | wc -l | tr -d ' '
}
function _count_files_on_host_without_unison_tpm_files() {
  _files_on_host_without_unison_tpm_files | wc -l | tr -d ' '
}

# Count the files in the container
# - excluding temporary .unison files
function _files_in_container() {
  docker exec magicsync_php_1 bash -c 'find /src/example/src -print | sed "s~/src/example~~g"'
}
function _files_in_container_without_unison_tpm_files() {
  docker exec magicsync_php_1 bash -c 'find /src/example/src -type d -name ".unison*" -prune -o -print | sed "s~/src/example~~g"'
}

# Count files in container
function _count_files_in_container() {
  _files_in_container | wc -l | tr -d ' '
}
function _count_files_in_container_without_unison_tpm_files() {
  _files_in_container_without_unison_tpm_files | wc -l | tr -d ' '
}

# Check if new files appears in container (syncing is ongoing)
# - displays the synced files so fat
# - perform a check every 2 seconds
function _has_new_files_in_container() {
  local files_in_container_previous=$(_count_files_in_container)
  sleep 5
  files_in_container=$(_count_files_in_container)
  echo "Synced $files_in_container files so far..."
  [ $files_in_container_previous -eq $files_in_container ] && return 1 || return 0
}


# Check if new files appears in container (syncing is ongoing)
# - displays the synced files so fat
# - perform a check every 2 seconds
function _has_new_files_on_host() {
  local files_on_host_previous=$(_count_files_on_host)
  sleep 5
  local files_on_host=$(_count_files_on_host)
  echo "Synced $files_on_host files so far..."
  [ $files_on_host_previous -eq $files_on_host ] && return 1 || return 0
}

# Remove all test containers
function _remove_existing_test_containers() {
  docker-compose -p magicsync -f ${DIR}/docker-compose.yml -f ${DIR}/docker-compose.development.yml down
}

# Build and start the test containers
function _build_and_start_test_containers() {
  docker-compose -p magicsync -f ${DIR}/docker-compose.yml -f ${DIR}/docker-compose.development.yml up -d --build
}

function _clean_test_directory() {
  git clean -xfd ${DIR}/src
}

function _display_test_result() {
  local in_container=$(_count_files_in_container)
  local on_host=$(_count_files_on_host)
  local in_container_no_tmp=$(_count_files_in_container_without_unison_tpm_files)
  local on_host_no_tmp=$(_count_files_on_host_without_unison_tpm_files)
  echo "Checking generated files"
  echo " - Files created in container: ${in_container}"
  echo " - Files created on host: ${on_host}"
  echo " - Files created in container without unison tmp files: ${in_container_no_tmp}"
  echo " - Files created on host without unisn tmp files: ${on_host_no_tmp}"

  if [ $in_container_no_tmp -eq $on_host_no_tmp ]; then
    echo "SYNC SUCCESSFUL !!!!"
  else
    echo "SYNC FAILED :("
    _files_on_host | sort > ${DIR}/hostfiles.txt
    _files_in_container_without_unison_tpm_files | sort > ${DIR}/containerfiles.txt
    echo "diff ${DIR}/hostfiles.txt ${DIR}/containerfiles.txt"
  fi
}