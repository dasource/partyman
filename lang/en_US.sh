
#echo "en_US"

messages=(

    ["partyman_version"]="partyman version"
    ["gathering_info"]="gathering info, please wait... "
    ["done"]=" done!"
    ["exiting"]="Exiting."

    ["days"]="days"
    ["hours"]="hours"
    ["mins"]="mins"
    ["secs"]="secs"

    ["YES"]="YES"
    ["NO"]="NO"
    ["FAILED"]="FAILED!"

    ["not_implemented"]="This feature is not implemented!"
    ["prompt_are_you_sure"]="Are you sure?"
    ["prompt_ipv4_ipv6"]="Host has both ipv4 and ipv6 addresses.\n - Use ipv6 for install?"

    ["download"]="download"
    ["downloading"]="Downloading"
    ["creating"]="Creating"
    ["checksum"]="checksum"
    ["checksumming"]="Checksumming"
    ["unpacking"]="Unpacking"
    ["stopping"]="Stopping"
    ["removing_old_version"]="Removing old version... "
    ["please_wait"]="Please wait..."
    ["try_again_later"]="Try again later."
    ["launching"]="Launching"
    ["bootstrapping"]="Bootstrapping"
    ["unzipping"]="Unzipping"
    ["waiting_for_particld_to_respond"]="Waiting for particld to respond... "
    ["deleting_cache_files"]="Deleting cache files, debug.log... "
    ["starting_particld"]="Starting particld... "

    ["err_downloading_file"]="error downloading file"
    ["err_tried_to_get"]="tried to get"
    ["err_no_pkg_mgr"]="cannot determine platform/package manager"
    ["err_missing_dependency"]="missing dependency:"
    ["err_unknown_platform"]="unknown platform:"
    ["err_partyman_supports"]="partyman currently supports 32/64bit linux and 32/64bit arm/aarch"
    ["err_could_not_get_version"]="Could not find latest version from"
    ["err_failed_ip_resolve"]="failed to resolve public ip. retrying... "

    ["newer_particl_available"]="a newer version of particl is available."
    ["successfully_upgraded"]="particl successfully upgraded to version"
    ["successfully_installed"]="successfully installed!"
    ["installed_in"]="Installed in"
    ["particl_version"]="particl version"
    ["is_not_uptodate"]="is not up to date."
    ["is_uptodate"]="is up to date."
    ["preexisting_dir"]="pre-existing directory"
    ["run_reinstall"]="Run 'partyman reinstall' to overwrite."
    ["reinstall_to"]="reinstall to"
    ["and_install_to"]="and install to"

    ["exec_found_in_system_dir"]="particl executables found in system dir"
    ["run_partyman_as_root"]=". Run partyman as root (sudo partyman command) to continue."
    ["particld_not_found"]="particld not found in"
    ["particlcli_not_found"]="particl-cli not found in"
    ["particlcli_not_found_in_cwd"]="cannot find particl-cli in current directory"

    ["sync_to_github"]="sync partyman to github now?"

    ["usage"]="USAGE"
    ["commands"]="COMMANDS"
    ["usage_title"]="installs, updates, and manages single-user particl daemons and wallets"
    ["usage_install_description"]="installs, updates, and manages single-user particl daemons and wallets"
    ["usage_update_description"]="updates particl to latest version and restarts (pending)"
    ["usage_restart_description"]="restarts particld and deletes:"
    ["usage_restart_description_now"]="will prompt user if not given the 'now' argument"
    ["usage_status_description"]="polls local and web sources and displays current status"
    ["usage_sync_description"]="updates partyman to latest github version"
    ["usage_branch_description"]="switch partyman to an alternate/experimental github branch"
    ["usage_reinstall_description"]="overwrites particl with latest version and restarts (pending)"
    ["usage_version_description"]="prints partymans version number and exits"
    ["usage_stakingnode_description"]="displays current cold staking wallets on this particl daemon"
    ["usage_stakingnode_init_description"]="[init] creates a new wallet"
    ["usage_stakingnode_new_description"]="[new] creates a new cold staking public key to use with your cold staking wallet"



    ["to_start_particl"]="To start particld run:"

    ["quit_uptodate"]="Up to date."

    ["requires_updating"]="requires updating. Latest version is:"
    ["requires_sync"]="Do 'git pull' manually or download the latest version."

    ["no_forks_detected"]="no forks detected"

    # space aligned strings. pay attention to spaces!
    ["currnt_version"]="  current version: "
    ["latest_version"]="   latest version: "

    ["status_hostnam"]="  hostname                      : "
    ["status_uptimeh"]="  host uptime/load average      : "
    ["status_particldip"]="  particld bind ip address      : "
    ["status_particldve"]="  particld version              : "
    ["status_uptodat"]="  particld up-to-date           : "
    ["status_running"]="  particld running              : "
    ["status_uptimed"]="  particld uptime               : "
    ["status_drespon"]="  particld responding (rpc)     : "
    ["status_dlisten"]="  particld listening  (ip)      : "
    ["status_dconnec"]="  particld connecting (peers)   : "
    ["status_dportop"]="  particld port open            : "
    ["status_dconcnt"]="  particld connection count     : "
    ["status_dblsync"]="  particld blocks synced        : "
    ["status_dbllast"]="  last block (local particld)   : "
    ["status_webchai"]="             (chainz)           : "
    ["status_dcurdif"]="  particld current difficulty   : "



    ["status_stakeen"]="  particld staking enabled      : "
    ["status_stakecu"]="  particld staking currently?   : "
    ["status_stakedi"]="  particld staking difficulty   : "
    ["status_stakewe"]="  particld staking weight       : "

    ["ago"]=" ago"
    ["found"]="found."
    ["breakline"]=""

    ["stakingnode_init_walletcheck"]="checking wallet ... "
    ["stakingnode_init_walletgenerate"]="recovery phrase : "
    ["stakingnode_init_walletcreate"]="creating wallet ... "
    ["stakingnode_new_publickey"]="creating new cold staking public new ... "
)
