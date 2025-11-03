FROM debian:12 AS builder

WORKDIR /tmp

# Install Dependencies
RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential curl unzip zlib1g-dev libpcre2-dev perl ca-certificates

# Download and Install upx
ENV UPX_VERSION=5.0.2

RUN curl -L https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-amd64_linux.tar.xz -o /tmp/upx.tar.xz \
 && tar -xf /tmp/upx.tar.xz -C /tmp \
 && mv /tmp/upx-${UPX_VERSION}-amd64_linux/upx /usr/local/bin/upx

# Download and Extract OpenSSL Source
ENV OPENSSL_VERSION=3.5.0

RUN curl -L -o /tmp/openssl.tar.gz https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz \
 && mkdir -p /tmp/openssl-src \
 && tar -xzvf /tmp/openssl.tar.gz -C /tmp/openssl-src --strip-components=1

# Download and Extract NGINX Source
ENV NGINX_VERSION=1.27.4

RUN curl -L -o /tmp/nginx.tar.gz http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
 && mkdir -p /tmp/nginx-src \
 && tar -xzvf /tmp/nginx.tar.gz -C /tmp/nginx-src --strip-components=1

# Build NGINX Statically with OpenSSL
RUN cd /tmp/nginx-src && ./configure \
        --with-http_ssl_module \
        --with-http_v2_module \
        --with-http_grpc_module \
        --with-openssl=/tmp/openssl-src \
        --with-openssl-opt=no-shared \
        --with-cc-opt='-static' \
        --with-ld-opt='-static' \
        --without-http_gzip_module \
 && make \
 && cp objs/nginx /tmp/nginx \
 && upx --best --lzma /tmp/nginx

FROM scratch

COPY --from=builder /tmp/nginx /nginx

ENTRYPOINT ["/nginx"]
