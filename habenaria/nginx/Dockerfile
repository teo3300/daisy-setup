# vim:foldmethod=marker:foldlevel=0

ARG NGINX_VERSION=SPECIFY_NGINX_VERSION

####################
# Builder image
####################

FROM nginx:${NGINX_VERSION} AS builder

# Install dependencies
# NOTE: Using libcre2 instead of libpcre3
RUN apt update && apt install -y \
    git \
    libpcre2-dev \
    zlib1g-dev \
    build-essential \
    libmaxminddb-dev \
    && rm -rf /var/lib/apt/lists/*

# Download nginx and extract
WORKDIR /usr/src
ADD http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz /usr/src/
RUN tar zxvf nginx-${NGINX_VERSION}.tar.gz

####################
# Modules
####################

# Geoip2
RUN git clone https://github.com/leev/ngx_http_geoip2_module.git /tmp/geoip2

# Build module
WORKDIR /usr/src/nginx-${NGINX_VERSION}
RUN ./configure --with-compat \
    --add-dynamic-module=/tmp/geoip2/ \
    && make

####################
# Deployed image
####################

FROM nginx:${NGINX_VERSION}

# Add runtime deps
RUN apt update && apt install -y \
    libmaxminddb0 \
    && rm -rf /var/lib/apt/lists/*

# Copy compiled module from builder to deployed
COPY --from=builder /usr/src/nginx-${NGINX_VERSION}/objs/ngx_http_geoip2_module.so   /etc/nginx/modules/

# Download and extract geoip database
ADD https://git.io/GeoLite2-Country.mmdb /etc/nginx/geoip/
