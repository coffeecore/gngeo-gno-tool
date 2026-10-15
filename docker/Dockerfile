FROM ubuntu:22.04 AS builder

ARG DEBIAN_FRONTEND=noninteractive
ARG GNGEO_REPO=https://github.com/coffeecore/gngeo-steward-fu.git
ARG GNGEO_REF=trimui-model-s

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        git \
        libsdl1.2-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone \
        --branch "${GNGEO_REF}" \
        --single-branch \
        "${GNGEO_REPO}" \
        /opt/gngeo \
    && cd /opt/gngeo \
    && make -f Makefile.host


FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libsdl1.2debian \
        zlib1g \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder \
    /opt/gngeo/build/host/gngeo-gno-dump \
    /usr/local/bin/gngeo-gno-dump

COPY docker/entrypoint.sh /usr/local/bin/gno-convert

RUN chmod +x \
    /usr/local/bin/gngeo-gno-dump \
    /usr/local/bin/gno-convert

ENTRYPOINT ["gno-convert"]
