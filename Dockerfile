FROM alpine:edge
MAINTAINER Mickaël Perrin <dev@mickaelperrin.fr>

ARG UNISON_VERSION=2.48.4
ARG FSWATCH_VERSION=1.9.2
ENV DOCKERGEN_VERSION=0.7.3

RUN apk add --update build-base curl bash supervisor py-pip curl && \
    apk add --update-cache --repository http://dl-4.alpinelinux.org/alpine/edge/testing/ ocaml shadow && \
    curl -L https://github.com/bcpierce00/unison/archive/$UNISON_VERSION.tar.gz | tar zxv -C /tmp && \
    curl --insecure https://bootstrap.pypa.io/ez_setup.py -o /tmp/ez_setup.py && \
    cd /tmp/unison-${UNISON_VERSION} && \
    sed -i -e 's/GLIBC_SUPPORT_INOTIFY 0/GLIBC_SUPPORT_INOTIFY 1/' src/fsmonitor/linux/inotify_stubs.c && \
    make && \
    cp src/unison src/unison-fsmonitor /usr/local/bin && \
    curl -L https://github.com/emcrisostomo/fswatch/releases/download/${FSWATCH_VERSION}/fswatch-${FSWATCH_VERSION}.tar.gz | tar zxv -C /tmp && \
    cd /tmp/fswatch-${FSWATCH_VERSION} && \
    ./configure && make && make install && make clean && make distclean && \
    curl -L https://github.com/jwilder/docker-gen/releases/download/$DOCKERGEN_VERSION/docker-gen-linux-amd64-$DOCKERGEN_VERSION.tar.gz | tar -C /usr/local/bin -xzv && \
    apk del curl emacs build-base ocaml && \
    apk --update add libgcc libstdc++ && \
    rm -rf /var/cache/apk/* && \
    rm -rf /tmp/unison-${UNISON_VERSION} && \
    rm -rf /tmp/fswatch-${FSWATCH_VERSION}
RUN apk add --update ca-certificates wget sudo && update-ca-certificates && wget -O cacert.pem https://curl.haxx.se/ca/cacert.pem && \
    mv cacert.pem ca-bundle.crt && \
    mkdir -p /etc/pki/tls/certs && \
    sudo mv ca-bundle.crt /etc/pki/tls/certs && \
    python /tmp/ez_setup.py && \
    pip install pyyaml && \
    rm /tmp/ez_setup.py

# These can be overridden later
ENV TZ="Europe/Paris" \
    LANG="C.UTF-8"

COPY mounts.tmpl /mounts.tmpl
COPY config_sync.py /config_sync.py
COPY entrypoint.sh /entrypoint.sh
COPY supervisord.conf /etc/supervisord.conf
COPY supervisor.fswatch.tpl.conf /supervisor.fswatch.tpl.conf
COPY supervisor.unison.tpl.conf /supervisor.unison.tpl.conf
COPY sync.sh /sync.sh

RUN mkdir -p /docker-entrypoint.d \
 && chmod +x /entrypoint.sh \
 && mkdir -p /etc/supervisor/conf.d \
 && chmod +x /sync.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord"]