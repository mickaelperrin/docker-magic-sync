#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE=docker-magic-sync

build () {
	echo "${DIR}"
	cd "${DIR}"
	docker build -t ${MY_DOCKER_HUB}/${IMAGE}:latest .
}

is_clean() {

	if ! git diff --exit-code > /dev/null; then
		echo "Git directory not clean. Aborting..."
		echo
		git diff
		exit 1
	fi

	if [ "$(git ls-files --other --exclude-standard --directory)" -neq 0 ]; then
		echo "Some files are not under version control. Aborting..."
		echo
		git ls-files --other --exclude-standard --directory
		exit 1
	fi
}

release() {
	cd ${DIR}
	is_clean
	git pull
	docker run --rm -v "${DIR}":/app treeder/bump patch
	version=$(cat ${DIR}/VERSION)
	build
	git tag -a "${version}" -m "v${version}"
	git push
	git push --tags
	docker tag ${MY_DOCKER_HUB}/${IMAGE}:latest ${MY_DOCKER_HUB}/${IMAGE}:${version}
	docker push ${MY_DOCKER_HUB}/${IMAGE}:${version}
	docker push ${MY_DOCKER_HUB}/${IMAGE}:latest
}

function_exists() {
    declare -f -F $1 > /dev/null
    return $?
}

if ! function_exists $1; then
 echo "$1 is not an available command"
else
	$1
fi
