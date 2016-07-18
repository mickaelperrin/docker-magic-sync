#!/usr/bin/env bash

volume=$1
port=$2
name=$3
user=$4
homedir=$5
reverse=$6
buffer=10
lastrun=/tmp${volume}.lastrun
reexec=/tmp${volume}.reexec

[ -z $reverse ] && fswatch_source=fswatch-${name} || fswatch_source=fswatch-${name}-reverse
[ -z $reverse ] && fswatch_destination=fswatch-${name}-reverse || fswatch_destination=fswatch-${name}
[ -z $reverse ] && volume_reverse=${volume%.*} || volume_reverse=${volume}.magic
[ -z $reverse ] && volume=${volume}.magic || volume=${volume}

echo "-----------------------------------------------------------------------------------------------------"
echo "Starting sync"
echo
echo "Watcher: fswatch-${name}${reverse}"
echo "Volume: ${volume}"
echo "Volume reverse: ${volume_reverse}"

if [ -d /tmp${volume_reverse}.reexec ]; then
    echo "Skipping reverse sync in progress..."
else
    if [ -d $reexec ]; then
        echo "Buffering..."
        touch $reexec
    else
        echo "Creating reexec directory..."
        mkdir -p $reexec
        echo "Disabling destination fswatch..."
        supervisorctl stop $fswatch_destination
        echo "Entering loop"
        while [ -d $reexec ]; do
            reexec_time=`stat -c %X $reexec`
            echo "Recexec time is ${reexec_time}"
            echo "Syncing...."
            sudo -H -n -u $user -- bash -c "cd $homedir && unison ${volume}.magic -auto -batch -owner -numericids -ignore='Path */.idea/' -ignore='Path */.git/' -ignore='Path */.unison*' socket://127.0.0.1:${port}" >> /tmp/unison.log
            if [ $(( `date +%s` - $reexec_time )) -le $buffer ]; then
                echo "Quick sync, sleeping while buffering"
                sleep $buffer
            fi
            if [ `stat -c %X $reexec` -eq $reexec_time ]; then
                echo "No watch triggered during sync. Nothing to sync"
                rmdir $reexec
            fi
        done
        supervisorctl start $fswatch_destination
        #supervisorctl restart $fswatch_source
    fi
fi