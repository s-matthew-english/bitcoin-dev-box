# testnet docker image

# Use phusion/baseimage as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/baseimage-docker/blob/master/Changelog.md for
# a list of version numbers.
FROM phusion/baseimage:0.9.16
MAINTAINER Paul Oliver <dockerpaul@paultastic.com>

ENV LAST_REFRESHED 20150412
ENV HOME /home/tester

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# add bitcoind from the official PPA
RUN apt-get update
RUN apt-get install --yes python-software-properties
RUN add-apt-repository --yes ppa:bitcoin/bitcoin

# Yes, you need to run apt-get update again after adding the bitcoin ppa
RUN apt-get update

# install bitcoind (from PPA) and make
RUN apt-get install --yes bitcoind make wget

# Install libs required for building bitcoin
RUN apt-get install --yes vim git gcc libboost-all-dev build-essential libtool autotools-dev autoconf pkg-config libssl-dev bsdmainutils sudo

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# change root password, should still be able to change back to root
RUN echo 'root:abc123' |chpasswd

# create a non-root user
RUN useradd -d /home/tester -m -s /bin/bash tester && echo "tester:tester" | chpasswd && adduser tester sudo

# copy the testnet-box files into the image
ADD . /home/tester/testnet

# make tester user own the testnet
RUN chown -R tester:tester /home/tester

# copy the bitcoin binaries to /usr/bin
RUN mv /home/tester/testnet/bin/* /usr/bin/
RUN rm -rf /home/tester/testnet/bin

# run following commands from user's home directory
# use the tester user when running the image
WORKDIR /home/tester
USER tester

# git clone the bitcoin source code, specifically the 0.10 branch
# This allows users to modify the bitcoin source code and rebuild it if they desire
RUN git clone -b 0.10 --single-branch https://github.com/bitcoin/bitcoin.git bitcoin

# git clone bitcoin-abe to be a local block explorer
RUN git clone https://github.com/bitcoin-abe/bitcoin-abe

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
WORKDIR /home/tester/testnet
RUN ln -s /home/tester/bitcoin /home/tester/testnet/src
RUN ln -s /home/tester/testnet /home/tester/bitcoin/testnet

# expose two rpc ports for the nodes to allow outside container access
EXPOSE 19001 19011
CMD ["/bin/bash"]
