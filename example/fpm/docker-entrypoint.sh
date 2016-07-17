#!/usr/bin/env bash
set -e

if [ "$1" == 'supervisor' ]; then

    # Check if a script is available in /lsyncd-entrypoint.d and source it
    for f in /sync-entrypoint.d/*; do
        case "$f" in
            *.sh) echo "$0: running $f"; . "$f" ;;
            *) echo "$0: ignoring $f" ;;
        esac
    done
fi

exec "$@"