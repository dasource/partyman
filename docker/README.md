# dockerized partyman

Easily setup and run partyman using Docker. This docker setup makes sure to always pull the latest / most stable version of partyman.

## TL;DR

Run `docker-compose up -d`

## Requirements

* Docker installed and running
  * [Install Docker](https://docs.docker.com/get-docker/)
  * [Install Docker Compose](https://docs.docker.com/compose/install/)
* ...

## Install (docker-compose)

1. Clone this repository on your server `git clone https://github.com/dasource/partyman.git`.
2. Run `docker-compose up -d`, this will build the image downloading and installing the latest release of partyman and particl-core and then run the container.
3. Wait for the blocks to get downloaded. While waiting, you could:
  - Run `./particl-cli.sh getblockcount` to check the blockcount from the running particld.
  - Run `docker-compose logs -f` to follow the logs to see whats happening.
  - Run `./partyman.sh status` to check the status via partyman.
4. Create new wallet `./partyman.sh stakingnode init` and write down your recovery phrase.
5. Create a Cold Staking Public Key `./partyman.sh stakingnode new`.
6. Enter the created Cold Staking Public Key to your Particl Wallet.
7. Done, the partyman status should now be available at http://localhost:8080

# Usage

Use `./partyman.sh` to run the partyman script inside the running container.
Use `./particl-cli.sh` to run particl-cli inside the running container.

## Install (using docker swarm)
