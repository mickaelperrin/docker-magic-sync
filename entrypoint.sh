#!/usr/bin/env bash
set -e

if [ "$1" == 'supervisord' ]; then

    # Increase the maximum watches for inotify for very large repositories to be watched
    # Needs the privilegied docker option
    [ ! -z $MAXIMUM_INOTIFY_WATCHES ] && echo fs.inotify.max_user_watches=$MAXIMUM_INOTIFY_WATCHES | tee -a /etc/sysctl.conf && sysctl -p || true

    # Generate a simple yaml file with all volumes of the current container
    # Used to find the magic volumes
    docker-gen -endpoint unix:///tmp/docker.sock /volumes.tmpl > /volumes.yml

    # Generate the sync configuration
    /config_sync.py "$SYNC_CONFIG_FILE"

    # Check if a SH script is available in /sync-entrypoint.d and source it
    # check if a YML configuration file is available in /sync-entrypoint.d and load it
    for f in /sync-entrypoint.d/*; do
        case "$f" in
            *.sh) echo "$0: running $f"; . "$f" ;;
            *.yml) echo "$0: parsing config file $f"; /config_sync.py "$f" ;;
            *) echo "$0: ignoring $f" ;;
        esac
    done
fi

exec "$@"