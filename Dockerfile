FROM debian:stretch-slim

ENV \
    DEBIAN_FRONTEND=noninteractive \
    NAXSI_VERSION=0.55.3 \
    OPENSSL_VERSION=1.1.0f \
    NPS_VERSION=1.12.34.2-stable \
    NGINX_VERSION=1.13.3 \
    HEADER_VERSION=0.33

RUN apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
      wget \
      ca-certificates \
      build-essential \
      libssl-dev \
      libpcre3 \
      libpcre3-dev \
      zlib1g \
      zlib1g-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*        
        
RUN cd \
    && wget https://github.com/openresty/headers-more-nginx-module/archive/v${HEADER_VERSION}.tar.gz \
    && tar -xvzf v${HEADER_VERSION}.tar.gz

RUN cd \
    && wget https://github.com/nbs-system/naxsi/archive/${NAXSI_VERSION}.tar.gz \
    && tar -xvzf ${NAXSI_VERSION}.tar.gz

RUN cd && wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz \
    && tar -xvzf openssl-${OPENSSL_VERSION}.tar.gz \
    && cd openssl-${OPENSSL_VERSION} \
    && ./config \
      --prefix=/usr/local \
      --openssldir=/usr/local/ssl \
    && make \
    && make install \
    && make clean

RUN cd \
    && wget https://github.com/pagespeed/ngx_pagespeed/archive/v${NPS_VERSION}.tar.gz \
    && tar -xvzf v${NPS_VERSION}.tar.gz \
    && cd incubator-pagespeed-ngx-${NPS_VERSION}/ \
    && [ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL) \
    && wget ${psol_url} \
    && tar -xvzf $(basename ${psol_url})  # extracts to psol/

RUN cd \
    && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    && tar -xzvf nginx-${NGINX_VERSION}.tar.gz \
    && cd nginx-${NGINX_VERSION} \
    && ./configure \
        --add-module=$HOME/naxsi-${NAXSI_VERSION}/naxsi_src \
        --add-module=$HOME/headers-more-nginx-module-${HEADER_VERSION}/ \
        --prefix=/usr/local/nginx \
        --user=www-data \
        --group=www-data \
        --sbin-path=/usr/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --with-pcre-jit \
        --with-threads \
        --with-http_realip_module \
        --with-http_gzip_static_module \
        --with-http_ssl_module \
        --with-openssl=$HOME/openssl-${OPENSSL_VERSION} \
        --with-http_v2_module \
        --with-http_stub_status_module \
        --add-module=$HOME/incubator-pagespeed-ngx-${NPS_VERSION} \
    && make \
    && make install

RUN rm -rf $HOME
RUN apt-get purge build-essential -y \
    && apt-get autoremove -y

VOLUME /var/run/nginx-cache

EXPOSE 80 443

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
