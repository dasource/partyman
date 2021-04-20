# dockerized partyman

Easily setup and run partyman using Docker. This docker setup makes sure to always pull the latest / most stable version of partyman and particl-core.

## TL;DR

```
docker-compose up -d
./partyman.sh stakingnode init
./partyman.sh stakingnode new
```

## Requirements

* Docker installed and running
  * [Install Docker](https://docs.docker.com/get-docker/)
  * [Install Docker Compose](https://docs.docker.com/compose/install/)

## Install (docker-compose)

1. Clone this repository on your server `git clone https://github.com/dasource/partyman.git`.
2. Run `docker-compose up -d`, this will build the image downloading and installing the latest release of partyman and particl-core and then run the container.
3. Wait for the blocks to get downloaded. While waiting, you could:
  - Run `./particl-cli.sh getblockcount` to check the blockcount from the running particld.
  - Run `docker-compose logs -f` to follow the logs to see what's happening.
  - Run `./partyman.sh status` to check the status via partyman.
4. Create new wallet `./partyman.sh stakingnode init` and write down your recovery phrase.
5. Create a Cold Staking Public Key `./partyman.sh stakingnode new`.
6. Enter the created Cold Staking Public Key to your Particl Wallet.
7. Done, the partyman status should now be available at [http://localhost:8080](http://localhost:8080).

### Basic Auth

TODO

## Install (docker swarm + Traefik)

0. [Create Swarm mode cluster](https://docs.docker.com/engine/swarm/swarm-tutorial/create-swarm/) first.
1. Create .env based on the example, configure your domain and traefik shared proxy network.
2. Configure Lets Encrypt certificate resolver and Cloudflare DNS.
3. Configure Basic Auth middleware.
4. Run `./deploy-partyman.sh` to deploy the partyman stack.
5. Wait for the blocks to get downloaded.
6. Create new wallet `./partyman.sh stakingnode init` and write down your recovery phrase.
7. Create a Cold Staking Public Key `./partyman.sh stakingnode new`.
8. Done, the partyman status should now be available at [https://partyman.yourdomain.com](https://partyman.yourdomain.com).

### Lets Encrypt + Cloudflare DNS

TODO

### Basic Auth

TODO

# Usage

- `./partyman.sh` to run the partyman script in the container.
- `./particl-cli.sh` to run particl-cli in the container.
- `./bash.sh` to get a bash shell in the container.

