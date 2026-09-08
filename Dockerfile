FROM alpine:3.23@sha256:fd791d74b68913cbb027c6546007b3f0d3bc45125f797758156952bc2d6daf40
RUN apk add --no-cache build-base linux-headers pkgconf bison perl file python3 musl-utils
COPY sources /sources
COPY sources.sha256 /sources.sha256
RUN cd /sources && sha256sum -c /sources.sha256
COPY build-container.sh /build-container.sh
RUN sh /build-container.sh
CMD ["sh", "-c", "cp -a /out/. /dist/"]
