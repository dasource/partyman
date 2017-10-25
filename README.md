# partyman

Particl wallet/daemon management utilities - version 0.1

* This script installs, updates, and manages single-user particl daemons and wallets
* This script provides the ability to create a new wallet and manage cold staking node

# Install/Usage

To install partyman do:

    sudo apt-get install python git unzip pv jq
    cd ~ && git clone https://github.com/dasource/partyman


To get the current status of particld, do:

    partyman/partyman status

To get the RPC command `getinfo` and `getwalletinfo` from particld, do:

    partyman/partyman getinfo



To perform a new install of particl, do:

    partyman/partyman install

To overwrite an existing particl install, do:

    partyman/partyman reinstall

To restart (or start) particld, do:

    partyman/partyman restart



To create a new wallet on this staking node, do:

    partyman/partyman stakingnode init

To create a new public key on this staking node, do:

    partyman/partyman stakingnode new

To get a list of public keys on this staking node, do:

    partyman/partyman stakingnode


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
