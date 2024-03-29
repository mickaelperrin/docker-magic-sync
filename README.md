Magic sync for docker
=====================

### Note: I don't use anymore this project and switched to Mutagen.

## Description

Magic sync for docker is a simple tool that watches local directory trees and syncs in real time the modification in a
container.

This image provides:
 - real time bi-directionnal syncing between your host and a container
 - full performance for your docker mounts (OSXFS, NFS, Vboxfs... are really slow especially for large code base)
 - simple configuration
 - docker only as a requirement

## Prerequesties

The mounted folders in the container must be abled to emit `inotify` events, currently this was tested only with OSXFS
(Docker for Mac).

## How to use

### Provided example

A full example is provided in the [example folder](https://github.com/mickaelperrin/docker-magic-sync/tree/master/example), it runs `composer install` of a Drupal project (large code base). To run it:

    cd example
    docker-compose -f docker-compose.yml -f docker-compose.development.yml up

Then, spawn in a new shell:

    docker exec -it example_php_1 bash -c 'composer --working-dir=/src/example/src install'

### Generic example

Here is an example on how to use it with a docker-compose file. The scenario illustrates a way to sync source code in real-time from the host inside
the container and get the output generated by the execution of the code back to the host.

The `app` container inits the volume `/src` where the code will reside.
The `magic-sync` container maps the local folder `./src` to the folder `/src.magic` with native mounts (osxfs)

    version: '2'

    services:
      app:
        image: alpine:latest
        command: /bin/true
        volumes:
        - /src
      php:
        build: ./fpm
        volumes_from:
        - app
      magic-sync:
        image: mickaelperrin/docker-magic-sync:latest
        environment:
        - SYNC_USER=www-data
        - SYNC_UID=33
        - SYNC_IGNORE_NAMES=.idea:.git
        - SYNC_IGNORE_PATHS=www/example:www2/example2
        #- MAXIMUM_INOTIFY_WATCHES=524288
        volumes:
        # Configure here the mappings between your host and the container.
        # Simply add a `.magic` extension to the volume path in the container.
        # the :cached is optional, but we hope it improves inotify events.
        - ./src:/src.magic:cached
        # this is needed for automatic discovery of mounted volumes in this container.
        - /var/run/docker.sock:/tmp/docker.sock:ro
        # If you want to configure USER / UID / IGNORE by volumes, you can use a simple YAML configuration file
        # - ./docker-syncs.yml:/sync-entrypoint.d/docker-syncs.yml
        volumes_from:
        - app
        # Privilegied mode is needed if you want to increase the maximum inotify watches for very large synced folders
        # by setting the ENV var MAXIMUM_INOTIFY_WATCHES.
        #privileged: true
        
### Start / stop sync process

To prevent crash of inotify events, you can stop the container before running an heavy files generation process (for example: a composer install commande).

```
docker exec -it project_magic-sync-1 bash -c 'supervisorctl stop unison--src'
docker exec -it project_magic-sync-1 bash -c 'supervisorctl start unison--src'
```

## Folders to sync

The mapping between the volumes to sync is done *magically* by looking for volumes mounted in the container that ends
with a `.magic` extension. They will be synced with a folder of the same name **without** the `.magic` extension.

### Configuration

Configuration is done through environment variables **and/or** YAML config file(s).
Configuration set in environment variables is used globally for all synced folders, except a specific value is defined
in a YAML config file. All yaml files provided in the `/sync-entrypoint.d` will be parsed as configuration files.

### User mapping

You can configure the user mapping by providing the user name **and** the uid of the user, through the ENV variables
`SYNC_USER` and `SYNC_UID`, or the `user` and `uid` entries in the YAML file.

### Ignore

You can configure the files / folders to ignore by providing the `-ignore` options that need to be passed to unison.
See the official documentation of unison on how to configure excludes.

### Advanced options

If you need to sync *very* large code base, you can run out of `inotify_watchers`, you can increase this amount by
providing the number you want in the ENV variable `MAXIMUM_INOTIFY_WATCHES`. Be aware that you need to set the `privileged`
option for the container in this case.

## Behind the scenes

This container uses:
 - `unison` for bi-directionnal syncing **and** file watching
 - `docker-gen` for volumes discovery

### Special thanks

Special thanks for [Eugen Mayer](https://github.com/EugenMayer) which makes me think about this implementation with OSXFS.

## WARNING
An issue with OSXFS prevents `inotify events` to get triggered in a mounted volume if the number of files created is high. This occurs when you perform a project initialisation like a `composer install` on a fresh project. Be sure, to stop the sync process before doing so, then re-eanble it to grab the generated files.  

### How to see the inotify bug

1. Run `docker exec -it magicsync_magic-sync_1 bash -c 'inotifywatch /src.magic/example/src/.gitignore'`
2. Edit on the host the .gitignore file in example/src
3. Kill the inotifywatch process. You got "No events occured"
4. Run `docker exec -it magicsync_magic-sync_1 bash -c 'inotifywatch /src.magic/example/src/.gitignore'`
5. Run `docker exec -it magicsync_magic-sync_1 bash -c 'echo "##test" >> /src.magic/example/src/.gitignore'`
6. Kill the inotifywatch process. You got "9      2       1       1            2              3     /src.magic/example/src/.gitignore"

## Disclaimer

Besides the usual disclaimer in the license, we want to specifically emphasize that the authors, and any organizations the authors are associated with, can not be held responsible for data-loss caused by possible malfunctions of Docker Magic Sync.

## License

[GPLv2](http://www.fsf.org/licensing/licenses/info/GPLv2.html) or any later GPL version.
