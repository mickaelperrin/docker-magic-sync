FROM alpine:latest
MAINTAINER Mickaël Perrin <dev@mickaelperrin.fr>

ARG UNISON_VERSION=2.48.4
ENV DOCKERGEN_VERSION=0.7.3

RUN apk add --update build-base curl bash inotify-tools && \
    apk add --update-cache --repository http://dl-4.alpinelinux.org/alpine/edge/testing/ ocaml shadow && \
    curl -L https://github.com/bcpierce00/unison/archive/$UNISON_VERSION.tar.gz | tar zxv -C /tmp && \
    curl --insecure https://bootstrap.pypa.io/ez_setup.py -o /tmp/ez_setup.py && \
    cd /tmp/unison-${UNISON_VERSION} && \
    sed -i -e 's/GLIBC_SUPPORT_INOTIFY 0/GLIBC_SUPPORT_INOTIFY 1/' src/fsmonitor/linux/inotify_stubs.c && \
    make UISTYLE=text NATIVE=true STATIC=true && \
    cp src/unison src/unison-fsmonitor /usr/local/bin && \
    curl -L https://github.com/jwilder/docker-gen/releases/download/$DOCKERGEN_VERSION/docker-gen-linux-amd64-$DOCKERGEN_VERSION.tar.gz | tar -C /usr/local/bin -xzv && \
    apk del curl emacs build-base ocaml && \
    rm -rf /var/cache/apk/* && \
    rm -rf /tmp/unison-${UNISON_VERSION}

RUN apk add --update build-base python py-pip && \
    apk add --update ca-certificates wget sudo && update-ca-certificates && wget -O cacert.pem https://curl.haxx.se/ca/cacert.pem && \
    mv cacert.pem ca-bundle.crt && \
    mkdir -p /etc/pki/tls/certs && \
    sudo mv ca-bundle.crt /etc/pki/tls/certs && \
    python /tmp/ez_setup.py && \
    pip install pyyaml && \
    rm /tmp/ez_setup.py

RUN apk add --update supervisor

# These can be overridden later
ENV TZ="Europe/Paris" \
    LANG="C.UTF-8"

COPY mounts.tmpl /mounts.tmpl
COPY config_sync.py /config_sync.py
COPY entrypoint.sh /entrypoint.sh
COPY supervisord.conf /etc/supervisord.conf
COPY supervisor.unison.tpl.conf /etc/supervisor.unison.tpl.conf

RUN mkdir -p /docker-entrypoint.d \
 && chmod +x /entrypoint.sh \
 && mkdir -p /etc/supervisor/conf.d

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord"]