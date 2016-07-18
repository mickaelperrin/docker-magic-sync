#!/usr/bin/env bash

volume=$1
port=$2
name=$3
reverse=$4
lastrun=/tmp${volume}.lastrun
reexec=/tmp${volume}.reexec

[ -z $reverse ] && fswatch_destination=fswatch-${name}-reverse || fswatch_destination=fswatch-${name}

if [ ! -d $lastrun ] || [ `stat -c %X $lastrun` -le $(( `date +%s` - buffer )) ]; then
    echo "No update since ${buffer} seconds, start syncing"
    [ -d $lastrun ] && touch $lastrun || mkdir -p $lastrun
    [ ! -d $reexec ] && mkdir -p $reexec
    while [ -d $reexec ]; do
        rmdir $reexec
        echo "Disabling destination fswatch..."
        supervisorctl stop $fswatch_destination
        echo "Syncing...."
        unison ${volume}.magic -auto -batch -owner -numericids socket://127.0.0.1:${port}
        sleep $buffer
    done
    supervisorctl start $fswatch_destination
else
    echo "Buffering..."
    [ -d $reexec ] && touch $reexec || mkdir -p $reexec
fi