FROM debian:12 AS builder

WORKDIR /tmp

# Install Dependencies
RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential curl unzip zlib1g-dev libpcre2-dev perl ca-certificates

# Download and Extract OpenSSL Source
ENV OPENSSL_VERSION=3.5.4

RUN curl -L -o /tmp/openssl.tar.gz https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz \
 && mkdir -p /tmp/openssl-src \
 && tar -xzvf /tmp/openssl.tar.gz -C /tmp/openssl-src --strip-components=1

# Download and Extract NGINX Source
ENV NGINX_VERSION=1.31.2

RUN curl -L -o /tmp/nginx.tar.gz http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
 && mkdir -p /tmp/nginx-src \
 && tar -xzvf /tmp/nginx.tar.gz -C /tmp/nginx-src --strip-components=1

# Build NGINX Statically with OpenSSL
RUN cd /tmp/nginx-src && ./configure \
        --with-http_ssl_module \
        --with-http_v2_module \
        --with-openssl=/tmp/openssl-src \
        --with-openssl-opt=no-shared \
        --with-cc-opt='-static' \
        --with-ld-opt='-static' \
        --without-http_gzip_module \
 && make \
 && cp objs/nginx /tmp/nginx

FROM rexezugedockerutils/upx AS upx

FROM debian:stable-slim AS compressor

COPY --from=builder /tmp/nginx /nginx

COPY --from=upx /upx /usr/local/bin/upx

RUN upx --best --lzma /nginx

FROM scratch

COPY --from=compressor /nginx /nginx

ENTRYPOINT ["/nginx"]
