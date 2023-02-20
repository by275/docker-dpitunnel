ARG ALPINE_VER=3.17

FROM ghcr.io/by275/base:alpine AS prebuilt
FROM ghcr.io/by275/base:alpine${ALPINE_VER} AS base

RUN \
    echo "**** install frolvlad/alpine-python3 ****" && \
    apk add --no-cache python3 && \
    if [ ! -e /usr/bin/python ]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --no-cache --upgrade pip setuptools wheel && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip; fi && \
    echo "**** cleanup ****" && \
    rm -rf \
        /tmp/* \
        /root/.cache

# 
# BUILD
# 
FROM base AS dpitunnel-cli

RUN \
    echo "**** build dpitunnel-cli ****" && \
    apk add --no-cache \
        git && \
    git clone https://github.com/nomoresat/DPITunnel-cli.git /tmp/dpitunnel --depth 1 && \
    cd /tmp/dpitunnel && \
    bash build_static_alpine.sh

# 
# COLLECT
# 
FROM base AS collector

# add s6-overlay
COPY --from=prebuilt /s6/ /bar/
ADD https://raw.githubusercontent.com/by275/docker-base/main/_/etc/cont-init.d/adduser /bar/etc/cont-init.d/10-adduser

# add dpitunnel-cli
COPY --from=dpitunnel-cli /tmp/dpitunnel/build/DPITunnel-cli-exec /bar/usr/local/bin/dpitunnel-cli

# add local files
COPY root/ /bar/

RUN \
    echo "**** permissions ****" && \
    chmod a+x \
        /bar/usr/local/bin/* \
        /bar/etc/cont-init.d/* \
        /bar/etc/s6-overlay/s6-rc.d/*/run

RUN \
    echo "**** s6: resolve dependencies ****" && \
    for dir in /bar/etc/s6-overlay/s6-rc.d/*; do mkdir -p "$dir/dependencies.d"; done && \
    for dir in /bar/etc/s6-overlay/s6-rc.d/*; do touch "$dir/dependencies.d/legacy-cont-init"; done && \
    echo "**** s6: create a new bundled service ****" && \
    mkdir -p /tmp/app/contents.d && \
    for dir in /bar/etc/s6-overlay/s6-rc.d/*; do touch "/tmp/app/contents.d/$(basename "$dir")"; done && \
    echo "bundle" > /tmp/app/type && \
    mv /tmp/app /bar/etc/s6-overlay/s6-rc.d/app && \
    echo "**** s6: deploy services ****" && \
    rm /bar/package/admin/s6-overlay/etc/s6-rc/sources/top/contents.d/legacy-services && \
    touch /bar/package/admin/s6-overlay/etc/s6-rc/sources/top/contents.d/app

# 
# RELEASE
# 
FROM base
LABEL maintainer="by275"
LABEL org.opencontainers.image.source https://github.com/by275/docker-dpitunnel

RUN \
    echo "**** install python-proxy ****" && \
    apk add --no-cache \
        py3-pycryptodome \
        py3-uvloop \
        && \
    pip3 install pproxy[accelerated] && \
    echo "**** install others ****" && \
    apk add --no-cache \
        grep \
        moreutils \
        sed \
        && \
    echo "**** cleanup ****" && \
    rm -rf \
        /tmp/* \
        /root/.cache

COPY --from=collector /bar/ /

ENV \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    PYTHONUNBUFFERED=1 \
    TZ=Asia/Seoul \
    DT_ENABLED=true \
    DT_PORT=8080 \
    DT_USER_OPTS="--desync-attacks=disorder_fake --wrong-seq" \
    PROXY_ENABLED=true \
    PROXY_PORT=8008

EXPOSE ${DT_PORT} ${PROXY_PORT}
VOLUME /config

HEALTHCHECK --interval=10m --timeout=30s --start-period=10s --retries=3 \
    CMD /usr/local/bin/healthcheck

ENTRYPOINT ["/init"]
