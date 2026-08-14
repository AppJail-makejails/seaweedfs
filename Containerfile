ARG FREEBSD_RELEASE

FROM ghcr.io/appjail-makejails/core:${FREEBSD_RELEASE}

ARG NO_PKGCLEAN

LABEL org.opencontainers.image.title="SeaweedFS" \
    org.opencontainers.image.description="Distributed Object Store and Filesystem" \
    org.opencontainers.image.source="https://github.com/AppJail-makejails/seaweedfs" \
    org.opencontainers.image.url="https://github.com/AppJail-makejails/seaweedfs" \
    org.opencontainers.image.vendor="DtxdF" \
    org.opencontainers.image.authors="Jesús Daniel Colmenares Oviedo <dtxdf@disroot.org>"

RUN set -xe; \
    \
    pkg update; \
    pkg install seaweedfs; \
    \
    if [ -z "${NO_PKGCLEAN}" ]; then \
        pkg clean -a; \
        rm -rf /var/cache/pkg/*; \
    fi; \
    rm -rf /var/db/pkg/repos/*

COPY filer.toml /usr/local/etc/seaweedfs/filer.toml
COPY entrypoint.sh /

# volume server grpc port
EXPOSE 18080
# volume server http port
EXPOSE 8080
# filer server grpc port
EXPOSE 18888
# filer server http port
EXPOSE 8888
# master server shared grpc port
EXPOSE 19333
# master server shared http port
EXPOSE 9333
# s3 server http port
EXPOSE 8333
# webdav server http port
EXPOSE 7333

# Create data directory and set proper ownership for seaweed user
RUN mkdir -p /data/filerldb2 && \
    chmod 755 /entrypoint.sh

VOLUME /data
WORKDIR /data

# We'll switch to noroot.
USER root

# Entrypoint will handle permission fixes and user switching
ENTRYPOINT ["/entrypoint.sh"]
# Default to a complete single-process cluster (master+volume+filer+S3+admin)
# so the image is usable out of the box — including in environments like
# GitHub Actions service containers that cannot pass arguments to the entrypoint.
# Override with any other subcommand at `appjail oci run` / compose time.
CMD ["mini", "-dir=/data"]
