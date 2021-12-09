#!/usr/bin/env bash
set -ex

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE=docker-magic-sync
UNISON_VERSION=2.51.4
PUSH=${PUSH:-true}
RELEASE=${RELEASE:-false}
RELEASE_LATEST=${RELEASE_LATEST:-false}

build () {
	docker build -t ${MY_DOCKER_HUB}/${IMAGE}:latest ${DIR}
}

local() {
  REGISTRY=registry.gitlab.com/dkod-docker
  REV_TAG=$(git log -1 --pretty=format:%h)
  FQIN_RELEASE="${REGISTRY}/${IMAGE}:${UNISON_VERSION}"
  FQIN="${FQIN_RELEASE}-${REV_TAG}"

  docker --context default build \
    -t ${FQIN}-arm64 \
    --build-arg UNISON_VERSION=${UNISON_VERSION} \
    ${DIR}

  docker --context nuc build \
    -t ${FQIN}-amd64 \
    --build-arg UNISON_VERSION=${UNISON_VERSION} \
    ${DIR}

  docker manifest create ${FQIN} --amend ${FQIN}-amd64 --amend ${FQIN}-arm64

  if $PUSH; then
    docker --context default push ${FQIN}-arm64 || true
    docker --context nuc push ${FQIN}-amd64 || true
    docker manifest push ${FQIN} || true
  fi

  if $RELEASE; then
    docker manifest create ${FQIN_RELEASE} --amend ${FQIN}-amd64 --amend ${FQIN}-arm64
    docker manifest create ${FQIN_RELEASE} --amend ${FQIN}-amd64 --amend ${FQIN}-arm64
    docker manifest push ${FQIN_RELEASE}
  fi

  if $RELEASE_LATEST; then
    docker manifest create ${REGISTRY}/${IMAGE}:latest --amend ${FQIN}-amd64 --amend ${FQIN}-arm64
    docker manifest create ${REGISTRY}/${IMAGE}:latest --amend ${FQIN}-amd64 --amend ${FQIN}-arm64
    docker manifest push ${REGISTRY}/${IMAGE}:latest
  fi
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
