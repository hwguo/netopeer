FROM ubuntu:latest

# install required packages
RUN ["apt-get", "update"]
RUN ["apt-get", "install", "-y", "wget", "git", "apt-utils", "libtool-bin", "libtool", "pkg-config", "libxml2-dev", "python-libxml2", "libxslt1.1", "libxslt1-dev", "doxygen", "libcurl4-gnutls-dev", "libgcrypt11-dev", "libssl-dev", "xz-utils", "make", "cmake", "python-pip"]
RUN ["ssh-keygen", "-A"]
RUN ["pip", "install", "-U", "pip"]
RUN ["pip", "install", "pyang"]

# install zlib
RUN set -e -x; \
    wget http://downloads.sourceforge.net/project/libpng/zlib/1.2.8/zlib-1.2.8.tar.gz; \
    tar xvf zlib-1.2.8.tar.gz; \
    cd zlib-1.2.8; \
    ./configure; \
    make -j4; \
    make install

# install libssh (>=0.6.4)
RUN ["apt-get", "install", "-y", "libssh-4"]
RUN set -e -x; \
    cd ..; \
    wget https://red.libssh.org/attachments/download/121/libssh-0.6.5.tar.xz; \
    xz -d libssh-0.6.5.tar.xz; \
    tar xvf libssh-0.6.5.tar; \
    cd libssh-0.6.5; \
    if [ -e "CMakeCache.txt" ]; then rm CMakeCache.txt; fi; \
    mkdir build; \
    cd build; \
    cmake ..; \
    make -j4; \
    make install

# clone, build and install libnetconf
RUN ["apt-get", "install", "-y", "xsltproc"]
RUN set -e -x; \
    cd ../..; \
    git clone https://github.com/CESNET/libnetconf.git /usr/src/libnetconf; \
    cd /usr/src/libnetconf; \
    ./configure --prefix='/usr'; \
    make -j4; \
    make install

# build and install netopeer-server
COPY server /usr/src/netopeer/server
RUN set -e -x; \
    cd /usr/src/netopeer/server; \
    ./configure --prefix='/usr'; \
    make -j4; \
    make install; \
    cp -v config/datastore.xml /usr/etc/netopeer/cfgnetopeer/datastore.xml

# change user and password
RUN echo "root:mypassword" | chpasswd

# run netopeer-server
COPY config/datastore-server.xml /usr/etc/netopeer/cfgnetopeer
CMD ["/usr/bin/netopeer-server", "-v", "2"]

# expose ports
EXPOSE 830
