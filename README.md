# bitcoin-dev-box

**Have you ever wanted to experiment with modifying the bitcoin source code?**

This is *the perfect* way to dip your toes into bitcoin development.

**I highly recommend running this inside a docker container.**

This is a private, bitcoin, testnet-in-a-box. It's a fork of **freewil/bitcoin-testnet-box** that also allows you to build `bitcoind` and `bitcoin-cli` from source.

You must have `bitcoind` and `bitcoin-cli` installed on your system and in the
path unless running this within a [Docker](https://www.docker.io) container
(see [below](#using-with-docker)).

[![docker stats](http://dockeri.co/image/poliver/bitcoin-dev-box)](https://registry.hub.docker.com/u/poliver/bitcoin-dev-box/)

### Running docker container

The docker image will run two bitcoin nodes in the background and is meant to be attached to allow you to type in commands. The image also exposes the two JSON-RPC ports from the nodes if you want to be able to access them from outside the container.

* `$ docker run -ti --name btcdev -P -p 49020:19000 poliver/bitcoin-dev-box`

## Starting the testnet-box

This will start up two nodes using the two datadirs `1` and `2`. They
will only connect to each other in order to remain an isolated private testnet.
Two nodes are provided, as one is used to generate blocks and it's balance
will be increased as this occurs (imitating a miner). You may want a second node
where this behavior is not observed.

Node `1` will listen on port `19000`, allowing node `2` to connect to it.

Node `1` will listen on port `19001` and node `2` will listen on port `19011`
for the JSON-RPC server.

```
$ make start
```

## Check the status of the nodes

```
$ make getinfo
bitcoin-cli -datadir=1  getinfo
{
    "version" : 90300,
    "protocolversion" : 70002,
    "walletversion" : 60000,
    "balance" : 0.00000000,
    "blocks" : 0,
    "timeoffset" : 0,
    "connections" : 1,
    "proxy" : "",
    "difficulty" : 0.00000000,
    "testnet" : false,
    "keypoololdest" : 1413617762,
    "keypoolsize" : 101,
    "paytxfee" : 0.00000000,
    "relayfee" : 0.00001000,
    "errors" : ""
}
bitcoin-cli -datadir=2  getinfo
{
    "version" : 90300,
    "protocolversion" : 70002,
    "walletversion" : 60000,
    "balance" : 0.00000000,
    "blocks" : 0,
    "timeoffset" : 0,
    "connections" : 1,
    "proxy" : "",
    "difficulty" : 0.00000000,
    "testnet" : false,
    "keypoololdest" : 1413617762,
    "keypoolsize" : 101,
    "paytxfee" : 0.00000000,
    "relayfee" : 0.00001000,
    "errors" : ""
}
```

## Generating blocks

Normally on the live, real, bitcoin network, blocks are generated, on average, every 10 minutes. Since this testnet-in-box uses Bitcoin Core's (bitcoind) regtest mode, we are able to generate a block on a private network instantly using a simple command.

To generate a block:

```
$ make generate
```

To generate more than 1 block:

```
$ make generate BLOCKS=10
```

In order to create a balance that you can send to another address, you need to generate at least 100 blocks:

```
$ make generate BLOCKS=100
```

## Sending bitcoins
To send bitcoins that you've generated:

```
$ make send ADDRESS=mxwPtt399zVrR62ebkTWL4zbnV1ASdZBQr AMOUNT=10
```

## Sending bitcoins back to node 1
After sending bitcoins (generated on node 1) to node 2, send them back to node 1. In order to do so you will need to get a new address for node 1. You can optionally specify an account on node 1 to associate the address with.

```
$ make address ACCOUNT=testwithdrawals
```

## Sending bitcoins to node2

You first generate an address for node2:

```
$ make address2
bitcoin-cli -datadir=2  getnewaddress
mtRipU3BueyarTRcWsKjKXgGsUWMdcWDzD
```

We see an address for node2 is `mtRipU3BueyarTRcWsKjKXgGsUWMdcWDzD`. You can use your bitcoin client to send bitcoin to the address or you can send it from node1 using `make send ADDRESS=mtRipU3BueyarTRcWsKjKXgGsUWMdcWDzD AMOUNT=1.5`.

## Stopping the testnet-box

```
$ make stop
```

To clean up any files created while running the testnet and restore to the
original state:

```
$ make clean
```

## Connecting to your bitcoin regtest testnet using Bitcoin-QT

You can use the [Bitcoin-QT](https://bitcoin.org/en/download) to connect to this docker container's bitcoin nodes. This is how you can do it on a Mac:

```shell
# Example on a Mac
$ mkdir -p ~/localnet
$ /Applications/Bitcoin-Qt.app/Contents/MacOS/Bitcoin-Qt \
    -regtest -dnsseed=0 -connect=dockerhost:49020 \
    -datadir=./localnet/

# Example on Linux
$ mkdir -p ~/localnet
$ /path/to/bitcoin-qt \
    -regtest -dnsseed=0 -connect=localhost:49020 \
    -datadir=./localnet/

# Example on Windows
$ MKDIR $HOME\localnet
$ "C:\Program Files\Bitcoin\bitcoin-qt.exe" \
    -regtest -dnsseed=0 -connect=dockerhost:49020 \
    -datadir=$HOME/localnet
```

This assumes you are using port `49020` when you remapped your ports using docker

***Note to Mac or Windows Users**: `dockerhost` is typically `192.168.59.103`, but this can change based on your Oracle VirtualBox settings. You can always check for the IP address by running  `boot2docker ip` from the command line on Mac or Windows.*

## Modify bitcoin source code

Another cool feature of this docker container is it comes pre-loaded with the bitcoin source code. I've taken the time to install all the libraries bitcoin needs to be built. So you can modify the bitcoin source code, compile it, and the run your local testnet to see if your changes work. Here's how you can do that:

1. `cd ~/testnet/src`
1. Use an editor (vim comes installed on this container) to modify the source code
1. `cd ~/testnet/`
1. `make build` (this command stops bitcoind, rebuilds bitcoin, and then runs bitcoind again)

**Note: it will ask you the password for the `tester` user because it needs to use `sudo`. The password is `tester`.**

## Using with docker
This testnet-box can be used with [docker](https://www.docker.io/) to run it in an isolated container.

### Building docker image

Either pull the image:

```
docker pull poliver/bitcoin-dev-box
```

...or build it yourself from this directory:

```
docker build -t bitcoin-dev-box .
```

