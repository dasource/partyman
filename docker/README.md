# dockerized partyman

Easily setup and run partyman using Docker. This docker setup makes sure to always pull the latest / most stable version of partyman.

## TL;DR

Run `docker-compose up -d`

## Requirements

* Docker installed and running
  * [Install Docker](https://docs.docker.com/get-docker/)
  * [Install Docker Compose](https://docs.docker.com/compose/install/)
* ...

## Install (using docker-compose)

1. Within a terminal, run `docker-compose up -d`, this will download and install the latest release of partyman.
2. Run `./particl-cli.sh getblockcount` a couple of times to confirm that the blocks are being loaded
 or you could also run `docker-compose logs -f` to follow the logs to see whats happening.
3. Wait for the blocks to get downloaded. While waiting, you could:
  - Run `./particl-cli.sh getblockcount` to check the blockcount from the running particld.
  - Run `docker-compose logs -f` to follow the logs to see whats happening.
  - Run `./partyman.sh status` to check the status via partyman.

4. Create new wallet `./partyman.sh stakingnode init`.
5. Create a Cold Staking Public Key `./partyman.sh stakingnode new`.
6. Enter the created Cold Staking Public Key to your Particl Wallet.

# Usage

Use `./partyman.sh` to run the partyman script inside the running container.
Use `./particl-cli.sh` to run particl-cli inside the running container.

The partyman status will also be available at http://localhost:8080


# Commands

## install

"partyman install" downloads and initializes a fresh particl install into ~/.particl
unless already present

## reinstall

"partyman reinstall" downloads and overwrites existing particl executables, even if
already present

## restart

"partyman restart [now]" restarts (or starts) particld. Searches for particl-cli/particld
the current directory, ~/.particl, and $PATH. It will prompt to restart if not
given the optional 'now' argument.

## status

"partyman status" interrogates the locally running particld and displays its status

# Dependencies

* bash version 4
* nc (netcat)
* curl
* perl
* pv
* python
* unzip
* jq
* particld, particl-cli
* dnsutils
