FROM alpine
MAINTAINER Mickaël Perrin <dev@mickaelperrin.fr>

# Add edge repos
RUN echo "@edge http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories; \
    echo "@edgecommunity http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories; \
    echo "@edgetesting http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

ARG PYYAML_VERSION=3.12

RUN apk update \
 && apk add --no-cache --upgrade apk-tools@edgetesting \
 && apk add --no-cache shadow@edgetesting supervisor bash curl python2 \
 && curl -L http://pyyaml.org/download/pyyaml/PyYAML-${PYYAML_VERSION}.tar.gz | tar zxv -C /tmp \
 && cd /tmp/PyYAML-${PYYAML_VERSION} \
 && python setup.py --without-libyaml install \
 && apk del curl

ARG UNISON_VERSION=2.51.2

# Compile unison from source with inotify support and removes compilation tools
RUN apk add --no-cache --virtual .build-dependencies build-base curl \
 && apk add --no-cache inotify-tools \
 && apk add --no-cache ocaml \
 && curl -L https://github.com/bcpierce00/unison/archive/v$UNISON_VERSION.tar.gz | tar zxv -C /tmp \
 && cd /tmp/unison-${UNISON_VERSION} \
 && sed -i -e 's/GLIBC_SUPPORT_INOTIFY 0/GLIBC_SUPPORT_INOTIFY 1/' src/fsmonitor/linux/inotify_stubs.c \
 && make UISTYLE=text NATIVE=true STATIC=true \
 && cp src/unison src/unison-fsmonitor /usr/local/bin \
 && apk del .build-dependencies ocaml \
 && rm -rf /tmp/unison-${UNISON_VERSION}

ENV DOCKERGEN_VERSION=0.7.4

# Install docker-gen (to grab docker config on start)
RUN apk add --no-cache curl \
 && curl -L https://github.com/jwilder/docker-gen/releases/download/$DOCKERGEN_VERSION/docker-gen-linux-amd64-$DOCKERGEN_VERSION.tar.gz | tar -C /usr/local/bin -xzv \
 && apk del curl

# Install supervisord-stdout
RUN apk add --no-cache py-pip \
 && pip install supervisor-stdout \
 && apk del py-pip

# Install entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN mkdir -p /sync-entrypoint.d \
 && chmod +x /entrypoint.sh \
 && mkdir -p /etc/supervisor.conf.d

COPY volumes.tmpl /volumes.tmpl
COPY config_sync.py /config_sync.py
COPY supervisord.conf /etc/supervisord.conf
COPY supervisor.unison.tpl.conf /etc/supervisor.unison.tpl.conf

ENV TZ="Europe/Paris" \
    LANG="C.UTF-8"

ADD VERSION .

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord"]
