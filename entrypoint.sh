#!/usr/bin/env bash
set -e

if [ "$1" == 'supervisord' ]; then

    docker-gen -endpoint unix:///tmp/docker.sock /mounts.tmpl > /mounts.yml

    /config_sync.py "$SYNC_CONFIG_FILE"

    # Check if a script is available in /lsyncd-entrypoint.d and source it
    for f in /sync-entrypoint.d/*; do
        case "$f" in
            *.sh) echo "$0: running $f"; . "$f" ;;
            *.yml) echo "$0: parsing config file $f"; /config_sync.py "$f" ;;
            *) echo "$0: ignoring $f" ;;
        esac
    done
fi

exec "$@"