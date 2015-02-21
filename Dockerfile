# bitcoin-testnet-box docker image

# Use phusion/baseimage as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/baseimage-docker/blob/master/Changelog.md for
# a list of version numbers.
FROM phusion/baseimage:0.9.16
MAINTAINER Paul Oliver <paul@paultastic.com>

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# add bitcoind from the official PPA
RUN apt-get update
RUN apt-get install --yes python-software-properties
RUN add-apt-repository --yes ppa:bitcoin/bitcoin
RUN apt-get update

# install bitcoind (from PPA) and make
RUN apt-get install --yes bitcoind make wget

# Install libs required for building bitcoin
RUN apt-get install --yes vim git gcc libboost-all-dev build-essential libtool autotools-dev autoconf pkg-config libssl-dev bsdmainutils sudo

# create a non-root user
RUN useradd tester && echo "tester:tester" | chpasswd && adduser tester sudo
RUN mkdir -p /home/tester && chown -R tester:tester /home/tester

# run following commands from user's home directory
WORKDIR /home/tester

# copy the testnet-box files into the image
ADD . /home/tester/bitcoin-testnet-box

# make tester user own the bitcoin-testnet-box
RUN chown -R tester:tester /home/tester/bitcoin-testnet-box

# copy the bitcoin binaries to /usr/bin
RUN mv /home/tester/bitcoin-testnet-box/bin/* /usr/bin/
RUN rm -rf /home/tester/bitcoin-testnet-box/bin

# change root password, should still be able to change back to root
RUN echo 'root:abc123' |chpasswd

# use the tester user when running the image
USER tester

# git clone the bitcoin source code
RUN git clone https://github.com/bitcoin/bitcoin.git

# download and compile berkeley db 4.8 for wallets
RUN wget 'http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz'
RUN tar -xzvf db-4.8.30.NC.tar.gz
WORKDIR /home/tester/db-4.8.30.NC/build_unix
RUN mkdir -p /home/tester/bitcoin/db4
RUN ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=/home/tester/bitcoin/db4
RUN make install
WORKDIR /home/tester
RUN rm -rf db-4.8.30.NC
RUN rm -rf db-4.8.30.NC.tar.gz

# run commands from inside the testnet-box directory
WORKDIR /home/tester/bitcoin-testnet-box

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# expose two rpc ports for the nodes to allow outside container access
EXPOSE 19001 19011
CMD ["/bin/bash"]

