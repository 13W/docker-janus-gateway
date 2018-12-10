FROM debian:stretch

LABEL maintainer="Vladmir <zero@13w.me>"
LABEL description="Janus Gateway"

RUN apt update && \
    apt install -y \
      curl \
      build-essential \
      autogen \
      autoconf \
      automake \
      autotools-dev \
      pkg-config \
      gengetopt \
      gtk-doc-tools \
      cmake \
      libtool \
      libjansson-dev \
      libconfig-dev \
      libssl-dev \
      libmicrohttpd-dev \
      libnanomsg-dev \
      libcurl4-openssl-dev \
      libsofia-sip-ua-dev \
      libsofia-sip-ua-glib-dev \
      libopus-dev \
      libogg-dev \
      libre-dev

RUN bash -c "mkdir -p /tmp/{janus-gateway,libsrtp,usrsctp,libnice,libwebsockets/build}" && \
    bash -c 'function dl { echo -n "Downloading $1...";curl -L -sSko - $2 | tar --strip-components=1 -C /tmp/$1 -xzf - && echo "OK"; } && \
    dl janus-gateway https://github.com/meetecho/janus-gateway/archive/v0.5.0.tar.gz && \
    dl usrsctp https://github.com/sctplab/usrsctp/archive/master.tar.gz && \
    dl libsrtp https://github.com/cisco/libsrtp/archive/v2.2.0.tar.gz && \
    dl libnice https://gitlab.freedesktop.org/libnice/libnice/-/archive/0.1.14/libnice-0.1.14.tar.gz && \
    dl libwebsockets https://github.com/warmcat/libwebsockets/archive/v3.1-stable.tar.gz' &&  \
    echo "curl -L -sSko - https://github.com/meetecho/janus-gateway/archive/v0.5.0.tar.gz | tar --strip-components=1 -C /tmp/janus-gateway -xzf -" && \
    echo "curl -L -sSko - https://github.com/sctplab/usrsctp/archive/master.tar.gz | tar --strip-components=1 -C /tmp/usrsctp -xzf -" && \
    echo "curl -L -sSko - https://github.com/cisco/libsrtp/archive/v2.2.0.tar.gz | tar --strip-components=1 -C /tmp/libsrtp -xzf -" && \
    echo "curl -L -sSko - https://gitlab.freedesktop.org/libnice/libnice/-/archive/0.1.14/libnice-0.1.14.tar.gz | tar --strip-components=1 -C /tmp/libnice -xzf -" && \
    echo "curl -L -sSko - https://github.com/warmcat/libwebsockets/archive/v3.1-stable.tar.gz | tar --strip-components=1 -C /tmp/libwebsockets -xzf -" && \
    (echo "Building libsrtp"; cd /tmp/libsrtp; ./configure --prefix=/usr --enable-openssl && make shared_library && make install) && \
    (echo "Building usrsctp"; cd /tmp/usrsctp; ./bootstrap && ./configure --prefix=/usr --enable-openssl && make && make install) && \
    (echo "Building libnice"; cd /tmp/libnice; ./autogen.sh --prefix=/usr && make && make install) && \
    (echo "Building libwebsockets"; cd /tmp/libwebsockets/build; cmake -DLWS_MAX_SMP=1 -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_C_FLAGS="-fpic" .. && make && make install) && \
    echo "Building Janus Gateway" && \
    cd /tmp/janus-gateway && \
    ./autogen.sh && \
    ./configure --prefix=/opt/janus --disable-rabbitmq --disable-mqtt && \
    make && make install

RUN apt autoremove -y && \
    rm -rf /tmp/* /var/lib/apt/lists/*

EXPOSE 8088/tcp 8188/tcp
EXPOSE 8188/udp 20000-40000/udp

CMD /opt/janus/bin/janus --nat-1-1=${REAL_IP}

