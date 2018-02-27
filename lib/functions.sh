# vim: set filetype=sh ts=4 sw=4 et

# functions.sh - common functions and variables

# Copyright (c) 2015-2017 moocowmoo
# Copyright (c) 2017 dasource

# variables are for putting things in ----------------------------------------

C_RED="\e[31m"
C_YELLOW="\e[33m"
C_GREEN="\e[32m"
C_PURPLE="\e[35m"
C_CYAN="\e[36m"
C_NORM="\e[0m"

PARTYD_RUNNING=0
PARTYD_RESPONDING=0
PARTYMAN_VERSION=$(cat $PARTYMAN_GITDIR/VERSION)
DATA_DIR="$HOME/.particl"
DOWNLOAD_PAGE="https://github.com/particl/particl-core/releases"
#PARTYMAN_CHECKOUT=$(GIT_DIR=$PARTYMAN_GITDIR/.git GIT_WORK_TREE=$PARTYMAN_GITDIR git describe --dirty | sed -e "s/^.*-\([0-9]\+-g\)/\1/" )
#if [ "$PARTYMAN_CHECKOUT" == "v"$PARTYMAN_VERSION ]; then
    PARTYMAN_CHECKOUT=""
#else
#    PARTYMAN_CHECKOUT=" ("$PARTYMAN_CHECKOUT")"
#fi

curl_cmd="timeout 7 curl -s -L -A partyman/$PARTYMAN_VERSION"
wget_cmd='wget --no-check-certificate -q'


# (mostly) functioning functions -- lots of refactoring to do ----------------

pending(){ [[ $QUIET ]] || ( echo -en "$C_YELLOW$1$C_NORM" && tput el ); }

ok(){ [[ $QUIET ]] || echo -e "$C_GREEN$1$C_NORM" ; }

warn() { [[ $QUIET ]] || echo -e "$C_YELLOW$1$C_NORM" ; }
highlight() { [[ $QUIET ]] || echo -e "$C_PURPLE$1$C_NORM" ; }

err() { [[ $QUIET ]] || echo -e "$C_RED$1$C_NORM" ; }
die() { [[ $QUIET ]] || echo -e "$C_RED$1$C_NORM" ; exit 1 ; }

quit(){ [[ $QUIET ]] || echo -e "$C_GREEN${1:-${messages["exiting"]}}$C_NORM" ; echo ; exit 0 ; }

confirm() { read -r -p "$(echo -e "${1:-${messages["prompt_are_you_sure"]} [y/N]}")" ; [[ ${REPLY:0:1} = [Yy] ]]; }


up()     { echo -e "\e[${1:-1}A"; }
clear_n_lines(){ for n in $(seq ${1:-1}) ; do tput cuu 1; tput el; done ; }


usage(){
    cat<<EOF



    ${messages["usage"]}: ${0##*/} [command]

        ${messages["usage_title"]}

    ${messages["commands"]}

        install

            ${messages["usage_install_description"]}

        update

            ${messages["usage_update_description"]}

        reinstall

            ${messages["usage_reinstall_description"]}

        restart [now]

            ${messages["usage_restart_description"]}
                banlist.dat
                peers.dat

            ${messages["usage_restart_description_now"]}

	stakingnode [init, new, stats, rewardaddress]

	    ${messages["usage_stakingnode_description"]}
	    ${messages["usage_stakingnode_init_description"]}
	    ${messages["usage_stakingnode_new_description"]}
            ${messages["usage_stakingnode_stats_description"]}
            ${messages["usage_stakingnode_rewardaddress_description"]}

        status

            ${messages["usage_status_description"]}

	firewall [reset]

            ${messages["usage_firewall_description"]}
            ${messages["usage_firewall_reset"]}

        version

            ${messages["usage_version_description"]}

EOF
}

_check_dependencies() {

    (which python 2>&1) >/dev/null || die "${messages["err_missing_dependency"]} python - sudo apt-get install python"

    DISTRO=$(/usr/bin/env python -mplatform | sed -e 's/.*with-//g')
    if [[ $DISTRO == *"Ubuntu"* ]] || [[ $DISTRO == *"debian"* ]]; then
        PKG_MANAGER=apt-get
    elif [[ $DISTRO == *"centos"* ]]; then
        PKG_MANAGER=yum
    fi

    if [ -z "$PKG_MANAGER" ]; then
        (which apt-get 2>&1) >/dev/null || \
            (which yum 2>&1) >/dev/null || \
            die ${messages["err_no_pkg_mgr"]}

    fi

    (which curl 2>&1) >/dev/null || MISSING_DEPENDENCIES="${MISSING_DEPENDENCIES}curl "
    (which perl 2>&1) >/dev/null || MISSING_DEPENDENCIES="${MISSING_DEPENDENCIES}perl "
    (which git  2>&1) >/dev/null || MISSING_DEPENDENCIES="${MISSING_DEPENDENCIES}git "
    (which jq  2>&1) >/dev/null || MISSING_DEPENDENCIES="${MISSING_DEPENDENCIES}jq "
    (which dig  2>&1) >/dev/null || MISSING_DEPENDENCIES="${MISSING_DEPENDENCIES}dnsutils "

    if [ "$1" == "install" ]; then
        # only require unzip for install
        (which unzip 2>&1) >/dev/null || MISSING_DEPENDENCIES="${MISSING_DEPENDENCIES}unzip "
        (which pv   2>&1) >/dev/null || MISSING_DEPENDENCIES="${MISSING_DEPENDENCIES}pv "
    fi

    if [ "$1" == "firewall" ]; then
        # only require for firewall
        (which ufw  2>&1) >/dev/null || MISSING_DEPENDENCIES="${MISSING_DEPENDENCIES}ufw "
        FIREWALL_CLI="sudo ufw"
    fi

    # make sure we have the right netcat version (-4,-6 flags)
    if [ ! -z "$(which nc)" ]; then
        (nc -z -4 8.8.8.8 53 2>&1) >/dev/null
        if [ $? -gt 0 ]; then
            MISSING_DEPENDENCIES="${MISSING_DEPENDENCIES}netcat6 "
        fi
    else
        MISSING_DEPENDENCIES="${MISSING_DEPENDENCIES}netcat "
    fi

    if [ ! -z "$MISSING_DEPENDENCIES" ]; then
        err "${messages["err_missing_dependency"]} $MISSING_DEPENDENCIES\n"
        sudo $PKG_MANAGER install $MISSING_DEPENDENCIES
    fi
}

# attempt to locate particl-cli executable.
# search current dir, ~/.particl, `which particl-cli` ($PATH), finally recursive
_find_particl_directory() {

    INSTALL_DIR=''

    # particl-cli in PATH

    if [ ! -z $(which particl-cli 2>/dev/null) ] ; then
        INSTALL_DIR=$(readlink -f `which particl-cli`)
        INSTALL_DIR=${INSTALL_DIR%%/particl-cli*};

        #TODO prompt for single-user or multi-user install

        # if copied to /usr/*
        if [[ $INSTALL_DIR =~ \/usr.* ]]; then
            LINK_TO_SYSTEM_DIR=$INSTALL_DIR

            # if not run as root
            if [ $EUID -ne 0 ] ; then
                die "\n${messages["exec_found_in_system_dir"]} $INSTALL_DIR${messages["run_partyman_as_root"]} ${messages["exiting"]}"
            fi
        fi

    # particl-cli not in PATH

        # check current directory
    elif [ -e ./particl-cli ] ; then
        INSTALL_DIR='.' ;

        # check ~/.particl directory
    elif [ -e $HOME/.particl/particl-cli ] ; then
        INSTALL_DIR="$HOME/.particl" ;

    elif [ -e $HOME/particlcore/particl-cli ] ; then
        INSTALL_DIR="$HOME/particlcore" ;
    fi

    if [ ! -z "$INSTALL_DIR" ]; then
        INSTALL_DIR=$(readlink -f $INSTALL_DIR) 2>/dev/null
        if [ ! -e $INSTALL_DIR ]; then
            echo -e "${C_RED}${messages["particlcli_not_found_in_cwd"]}, ~/particlcore, or \$PATH. -- ${messages["exiting"]}$C_NORM"
            exit 1
        fi
    else
        echo -e "${C_RED}${messages["particlcli_not_found_in_cwd"]}, ~/particlcore, or \$PATH. -- ${messages["exiting"]}$C_NORM"
        exit 1
    fi

    PARTY_CLI="$INSTALL_DIR/particl-cli"

    # check INSTALL_DIR has particld and particl-cli
    if [ ! -e $INSTALL_DIR/particld ]; then
        echo -e "${C_RED}${messages["particld_not_found"]} $INSTALL_DIR -- ${messages["exiting"]}$C_NORM"
        exit 1
    fi

    if [ ! -e $PARTY_CLI ]; then
        echo -e "${C_RED}${messages["particlcli_not_found"]} $INSTALL_DIR -- ${messages["exiting"]}$C_NORM"
        exit 1
    fi

}


_check_partyman_updates() {
    GITHUB_PARTYMAN_VERSION=$( $curl_cmd -i https://raw.githubusercontent.com/dasource/partyman/master/VERSION 2>/dev/null | head -n 1 | cut -d$' ' -f2 )
    if [ "$GITHUB_PARTYMAN_VERSION" == 200 ]; then # check to make sure github is returning the data
        GITHUB_PARTYMAN_VERSION=$( $curl_cmd https://raw.githubusercontent.com/dasource/partyman/master/VERSION 2>/dev/null )
        if [ ! -z "$GITHUB_PARTYMAN_VERSION" ] && [ "$PARTYMAN_VERSION" != "$GITHUB_PARTYMAN_VERSION" ]; then
            echo -e "\n"
            echo -e "${C_RED}${0##*/} ${messages["requires_updating"]} $C_GREEN$GITHUB_PARTYMAN_VERSION$C_RED\n${messages["requires_sync"]}$C_NORM\n"

            die "${messages["exiting"]}"
        fi
    else
        GITHUB_PARTYMAN_VERSION=$PARTYMAN_VERSION # force to local version during github issues
    fi
}

_get_platform_info() {
    PLATFORM=$(uname -m)
    case "$PLATFORM" in
        i[3-6]86)
            BITS=32
	    ARM=0
	    ARCH='i686-pc-linux-gnu'
            ;;
        x86_64)
            BITS=64
	    ARM=0
	    ARCH='x86_64-linux-gnu'
            ;;
        armv7l)
            BITS=32
            ARM=1
            BIGARM=$(grep -E "(BCM2709|Freescale i\\.MX6)" /proc/cpuinfo | wc -l)
	    ARCH='arm-linux-gnueabihf'
            ;;
        aarch64)
            BITS=64
            ARM=1
            BIGARM=$(grep -E "(BCM2709|Freescale i\\.MX6)" /proc/cpuinfo | wc -l)
	    ARCH='aarch64-linux-gnu'
            ;;
        *)
            err "${messages["err_unknown_platform"]} $PLATFORM"
            err "${messages["err_partyman_supports"]}"
            die "${messages["exiting"]}"
            ;;
    esac
}

_get_versions() {
    _get_platform_info

    if [ -z "$PARTY_CLI" ]; then PARTY_CLI='echo'; fi
    CURRENT_VERSION=$( $PARTY_CLI --version | grep -m1 Particl | sed 's/\Particl Core RPC client version v//g' | sed 's/\.[^.]*$//' 2>/dev/null ) 2>/dev/null

    LVCOUNTER=0
    while [ -z "$LATEST_VERSION" ] && [ $LVCOUNTER -lt 5 ]; do
        PR=$( $curl_cmd https://api.github.com/repos/particl/particl-core/releases | jq -r .[$LVCOUNTER] 2>/dev/null | jq .prerelease)
	if [ "$PR" == "false" ]; then
	    LATEST_VERSION=$( $curl_cmd https://api.github.com/repos/particl/particl-core/releases | jq -r .[$LVCOUNTER] 2>/dev/null | jq -r .tag_name | sed 's/v//g')
	fi
        let LVCOUNTER=LVCOUNTER+1
    done

    if [ -z "$LATEST_VERSION" ] && [ $COMMAND == "install" ]; then
        die "\n${messages["err_could_not_get_version"]} $DOWNLOAD_PAGE -- ${messages["exiting"]}"
    fi

    DOWNLOAD_URL="https://github.com/particl/particl-core/releases/download/v"$LATEST_VERSION"/particl-"$LATEST_VERSION"-"$ARCH".tar.gz"
    DOWNLOAD_FILE="particl-"$LATEST_VERSION"-"$ARCH".tar.gz"

}

_check_particld_state() {
    _get_particld_proc_status
    PARTYD_RUNNING=0
    PARTYD_RESPONDING=0
    if [ $PARTYD_HASPID -gt 0 ] && [ $PARTYD_PID -gt 0 ]; then
        PARTYD_RUNNING=1
    fi
    if [ $( $PARTY_CLI help 2>/dev/null | wc -l ) -gt 0 ]; then
        PARTYD_RESPONDING=1
        PARTYD_WALLETSTATUS=$( $PARTY_CLI getwalletinfo | jq -r .encryptionstatus )
        PARTYD_WALLET=$( $PARTY_CLI getwalletinfo | jq -r .hdmasterkeyid )
        PARTYD_TBALANCE=$( $PARTY_CLI getwalletinfo | jq -r .total_balance )
    fi
}

restart_particld(){

    if [ $PARTYD_RUNNING == 1 ]; then
        pending " --> ${messages["stopping"]} particld. ${messages["please_wait"]}"
        $PARTY_CLI stop 2>&1 >/dev/null
        sleep 15
        killall -9 particld particl-shutoff 2>/dev/null
        ok "${messages["done"]}"
        PARTYD_RUNNING=0
    fi

    pending " --> ${messages["deleting_cache_files"]} $DATA_DIR/ "

    cd $INSTALL_DIR

    rm -rf \
        "$DATA_DIR"/banlist.dat \
        "$DATA_DIR"/peers.dat
    ok "${messages["done"]}"

    pending " --> ${messages["starting_particld"]}"
    $INSTALL_DIR/particld -daemon 2>&1 >/dev/null
    PARTYD_RUNNING=1
    PARTYD_RESPONDING=0
    ok "${messages["done"]}"

    pending " --> ${messages["waiting_for_particld_to_respond"]}"
    echo -en "${C_YELLOW}"
    while [ $PARTYD_RUNNING == 1 ] && [ $PARTYD_RESPONDING == 0 ]; do
        echo -n "."
        _check_particld_state
	sleep 5
    done
    if [ $PARTYD_RUNNING == 0 ]; then
        die "\n - particld unexpectedly quit. ${messages["exiting"]}"
    fi
    ok "${messages["done"]}"
    pending " --> particl-cli getinfo"
    echo
    $PARTY_CLI -getinfo
    echo

}

install_particld(){

    INSTALL_DIR=$HOME/particlcore
    PARTY_CLI="$INSTALL_DIR/particl-cli"

    if [ -e $INSTALL_DIR ] ; then
        die "\n - ${messages["preexisting_dir"]} $INSTALL_DIR ${messages["found"]} ${messages["run_reinstall"]} ${messages["exiting"]}"
    fi

    if [ -z "$UNATTENDED" ] ; then
        if [ $USER != "particl" ]; then  
            echo
            warn "We stronly advise you run this installer under user "particl" with sudo access. Are you sure you wish to continue as $USER?"
            if ! confirm " [${C_GREEN}y${C_NORM}/${C_RED}N${C_NORM}] $C_CYAN"; then
                echo -e "${C_RED}${messages["exiting"]}$C_NORM"
                echo ""
                exit 0
            fi
        fi
        pending "${messages["download"]} $DOWNLOAD_URL\n${messages["and_install_to"]} $INSTALL_DIR?"
    else
        echo -e "$C_GREEN*** UNATTENDED MODE ***$C_NORM"
    fi

    if [ -z "$UNATTENDED" ] ; then
        if ! confirm " [${C_GREEN}y${C_NORM}/${C_RED}N${C_NORM}] $C_CYAN"; then
            echo -e "${C_RED}${messages["exiting"]}$C_NORM"
            echo ""
            exit 0
        fi
    fi

    get_public_ips
    echo ""

    # prep it ----------------------------------------------------------------

    mkdir -p $INSTALL_DIR
    mkdir -p $DATA_DIR

    if [ ! -e $DATA_DIR/particl.conf ] ; then
        pending " --> ${messages["creating"]} $DATA_DIR/particl.conf... "

        while read; do
            eval echo "$REPLY"
        done < $PARTYMAN_GITDIR/particl.conf.template > "$DATA_DIR"/particl.conf
        ok "${messages["done"]}"
    fi

    # push it ----------------------------------------------------------------

    cd $INSTALL_DIR

    # pull it ----------------------------------------------------------------

    pending " --> ${messages["downloading"]} ${DOWNLOAD_URL}... "
    tput sc
    echo -e "$C_CYAN"
    $wget_cmd -O - $DOWNLOAD_URL | pv -trep -s27M -w80 -N wallet > $DOWNLOAD_FILE
    $wget_cmd -O - https://raw.githubusercontent.com/particl/gitian.sigs/master/$LATEST_VERSION.0-linux/tecnovert/particl-linux-$LATEST_VERSION-build.assert | pv -trep -w80 -N checksums > ${DOWNLOAD_FILE}.DIGESTS.txt
    echo -ne "$C_NORM"
    clear_n_lines 2
    tput rc
    clear_n_lines 3
    if [ ! -e $DOWNLOAD_FILE ] ; then
        echo -e "${C_RED}error ${messages["downloading"]} file"
        echo -e "tried to get $DOWNLOAD_URL$C_NORM"
        exit 1
    else
        ok ${messages["done"]}
    fi

    # prove it ---------------------------------------------------------------

    pending " --> ${messages["checksumming"]} ${DOWNLOAD_FILE}... "
    SHA256SUM=$( sha256sum $DOWNLOAD_FILE )
    SHA256PASS=$( grep $SHA256SUM ${DOWNLOAD_FILE}.DIGESTS.txt | wc -l )
    if [ $SHA256PASS -lt 1 ] ; then
	$wget_cmd -O - https://api.github.com/repos/particl/particl-core/releases | jq -r .[0] | jq .body > ${DOWNLOAD_FILE}.DIGESTS2.txt
	SHA256DLPASS=$( grep $SHA256SUM ${DOWNLOAD_FILE}.DIGESTS2.txt | wc -l )
	if [ $SHA256DLPASS -lt 1 ] ; then
	    echo -e " ${C_RED} SHA256 ${messages["checksum"]} ${messages["FAILED"]} ${messages["try_again_later"]} ${messages["exiting"]}$C_NORM"
            exit 1
	fi
    fi
    ok "${messages["done"]}"

    # produce it -------------------------------------------------------------

    pending " --> ${messages["unpacking"]} ${DOWNLOAD_FILE}... " && \
    tar zxf $DOWNLOAD_FILE && \
    ok "${messages["done"]}"

    # pummel it --------------------------------------------------------------

    if [ $PARTYD_RUNNING == 1 ]; then
        pending " --> ${messages["stopping"]} partcld. ${messages["please_wait"]}"
        $PARTY_CLI stop >/dev/null 2>&1
        sleep 15
        killall -9 particld particl-shutoff >/dev/null 2>&1
        ok "${messages["done"]}"
    fi

    # place it ---------------------------------------------------------------

    mv particl-$LATEST_VERSION/bin/particld particld-$LATEST_VERSION
    mv particl-$LATEST_VERSION/bin/particl-cli particl-cli-$LATEST_VERSION
    if [ $ARM != 1 ];then
        mv particl-$LATEST_VERSION/bin/particl-qt particl-qt-$LATEST_VERSION
    fi
    ln -s particld-$LATEST_VERSION particld
    ln -s particl-cli-$LATEST_VERSION particl-cli
    if [ $ARM != 1 ];then
        ln -s particl-qt-$LATEST_VERSION particl-qt
    fi

    # permission it ----------------------------------------------------------

    if [ ! -z "$SUDO_USER" ]; then
        chown -h $USER:$USER {$DOWNLOAD_FILE,${DOWNLOAD_FILE}.DIGESTS.txt,particl-cli,particld,particl-qt,particl*$LATEST_VERSION}
    fi

    # purge it ---------------------------------------------------------------

    rm -rf particl-$LATEST_VERSION

    # path it ----------------------------------------------------------------

    pending " --> adding $INSTALL_DIR PATH to ~/.bash_aliases ... "
    if [ ! -f ~/.bash_aliases ]; then touch ~/.bash_aliases ; fi
    sed -i.bak -e '/partyman_env/d' ~/.bash_aliases
    echo "export PATH=$INSTALL_DIR:\$PATH; # partyman_env" >> ~/.bash_aliases
    ok "${messages["done"]}"

    # autoboot it ------------------------------------------------------------

    INIT=$(ps --no-headers -o comm 1)
    if [ $INIT == "systemd" ] && [ "$USER" == "particl" ] && [ ! -z "$SUDO_USER" ]; then
        pending " --> detecting $INIT for auto boot ($USER) ... "
	ok ${messages["done"]}
	DOWNLOAD_SERVICE="https://raw.githubusercontent.com/particl/particl-core/master/contrib/init/particld.service"
        pending " --> [systemd] ${messages["downloading"]} ${DOWNLOAD_SERVICE}... "
	$wget_cmd -O - $DOWNLOAD_SERVICE | pv -trep -w80 -N service > particld.service
        if [ ! -e particld.service ] ; then
           echo -e "${C_RED}error ${messages["downloading"]} file"
           echo -e "tried to get particld.service$C_NORM"
        else
           ok ${messages["done"]}
	   pending " --> [systemd] installing service ... "
	   if sudo cp -rf particld.service /etc/systemd/system/; then
	       ok ${messages["done"]}
	   fi
           pending " --> [systemd] reloading systemd service ... "
	   if sudo systemctl daemon-reload; then
	       ok ${messages["done"]}
	   fi
           pending " --> [systemd] enable particld system startup ... "
	   if sudo systemctl enable particld; then
               ok ${messages["done"]}
           fi
        fi
    fi

    # poll it ----------------------------------------------------------------

    _get_versions

    # pass or punt -----------------------------------------------------------

    if [ $LATEST_VERSION == $CURRENT_VERSION ]; then
        echo -e ""
        echo -e "${C_GREEN}Particl ${LATEST_VERSION} ${messages["successfully_installed"]}$C_NORM"

        echo -e ""
        echo -e "${C_GREEN}${messages["installed_in"]} ${INSTALL_DIR}$C_NORM"
        echo -e ""
        ls -l --color {$DOWNLOAD_FILE,${DOWNLOAD_FILE}.DIGESTS.txt,particl-cli,particld,particl-qt,particl*$LATEST_VERSION}
        echo -e ""

        if [ ! -z "$SUDO_USER" ]; then
            echo -e "${C_GREEN}Symlinked to: ${LINK_TO_SYSTEM_DIR}$C_NORM"
            echo -e ""
            ls -l --color $LINK_TO_SYSTEM_DIR/{particld,particl-cli}
            echo -e ""
        fi

    else
        echo -e "${C_RED}${messages["particl_version"]} $CURRENT_VERSION ${messages["is_not_uptodate"]} ($LATEST_VERSION) ${messages["exiting"]}$C_NORM"
        exit 1
    fi
}

update_particld(){

    if [ $LATEST_VERSION != $CURRENT_VERSION ] || [ ! -z "$REINSTALL" ] ; then

        if [ ! -z "$REINSTALL" ];then
            echo -e ""
            echo -e "$C_GREEN*** ${messages["particl_version"]} $CURRENT_VERSION is up-to-date. ***$C_NORM"
            echo -e ""
            echo -en

            pending "${messages["reinstall_to"]} $INSTALL_DIR$C_NORM?"
        else
            echo -e ""
            echo -e "$C_RED*** ${messages["newer_particl_available"]} ***$C_NORM"
            echo -e ""
            echo -e "${messages["currnt_version"]} $C_RED$CURRENT_VERSION$C_NORM"
            echo -e "${messages["latest_version"]} $C_GREEN$LATEST_VERSION$C_NORM"
            echo -e ""
            if [ -z "$UNATTENDED" ] ; then
                pending "${messages["download"]} $DOWNLOAD_URL\n${messages["and_install_to"]} $INSTALL_DIR?"
            else
                echo -e "$C_GREEN*** UNATTENDED MODE ***$C_NORM"
            fi
        fi


        if [ -z "$UNATTENDED" ] ; then
            if ! confirm " [${C_GREEN}y${C_NORM}/${C_RED}N${C_NORM}] $C_CYAN"; then
                echo -e "${C_RED}${messages["exiting"]}$C_NORM"
                echo ""
                exit 0
            fi
        fi

        # push it ----------------------------------------------------------------

        cd $INSTALL_DIR

        # pull it ----------------------------------------------------------------

        pending " --> ${messages["downloading"]} ${DOWNLOAD_URL}... "
        tput sc
        echo -e "$C_CYAN"
        $wget_cmd -O - $DOWNLOAD_URL | pv -trep -s27M -w80 -N wallet > $DOWNLOAD_FILE
        $wget_cmd -O - https://raw.githubusercontent.com/particl/gitian.sigs/master/$LATEST_VERSION.0-linux/tecnovert/particl-linux-$LATEST_VERSION-build.assert | pv -trep -w80 -N checksums > ${DOWNLOAD_FILE}.DIGESTS.txt
        echo -ne "$C_NORM"
        clear_n_lines 2
        tput rc
        clear_n_lines 3
        if [ ! -e $DOWNLOAD_FILE ] ; then
            echo -e "${C_RED}error ${messages["downloading"]} file"
            echo -e "tried to get $DOWNLOAD_URL$C_NORM"
            exit 1
        else
            ok ${messages["done"]}
        fi

        # prove it ---------------------------------------------------------------

        pending " --> ${messages["checksumming"]} ${DOWNLOAD_FILE}... "
        SHA256SUM=$( sha256sum $DOWNLOAD_FILE )
        SHA256PASS=$( grep $SHA256SUM ${DOWNLOAD_FILE}.DIGESTS.txt | wc -l )
        if [ $SHA256PASS -lt 1 ] ; then
            $wget_cmd -O - https://api.github.com/repos/particl/particl-core/releases | jq -r .[0] | jq .body > ${DOWNLOAD_FILE}.DIGESTS2.txt
            SHA256DLPASS=$( grep $SHA256SUM ${DOWNLOAD_FILE}.DIGESTS2.txt | wc -l )
            if [ $SHA256DLPASS -lt 1 ] ; then
                echo -e " ${C_RED} SHA256 ${messages["checksum"]} ${messages["FAILED"]} ${messages["try_again_later"]} ${messages["exiting"]}$C_NORM"
                exit 1
            fi
        fi
        ok "${messages["done"]}"

        # produce it -------------------------------------------------------------

        pending " --> ${messages["unpacking"]} ${DOWNLOAD_FILE}... " && \
        tar zxf $DOWNLOAD_FILE && \
        ok "${messages["done"]}"

        # pummel it --------------------------------------------------------------

        if [ $PARTYD_RUNNING == 1 ]; then
            pending " --> ${messages["stopping"]} partcld. ${messages["please_wait"]}"
            $PARTY_CLI stop >/dev/null 2>&1
            sleep 15
            killall -9 particld particl-shutoff >/dev/null 2>&1
            ok "${messages["done"]}"
        fi

        # prune it ---------------------------------------------------------------

        pending " --> ${messages["removing_old_version"]}"
        rm -rf \
            particld \
            particld-$CURRENT_VERSION \
            particl-qt \
            particl-qt-$CURRENT_VERSION \
            particl-cli \
            particl-cli-$CURRENT_VERSION
        rm -rf \
	    "$DATA_DIR"/banlist.dat \
            "$DATA_DIR"/peers.dat
        ok "${messages["done"]}"

        # place it ---------------------------------------------------------------

        mv particl-$LATEST_VERSION/bin/particld particld-$LATEST_VERSION
        mv particl-$LATEST_VERSION/bin/particl-cli particl-cli-$LATEST_VERSION
        if [ $ARM != 1 ];then
            mv particl-$LATEST_VERSION/bin/particl-qt particl-qt-$LATEST_VERSION
        fi
        ln -s particld-$LATEST_VERSION particld
        ln -s particl-cli-$LATEST_VERSION particl-cli
        if [ $ARM != 1 ];then
            ln -s particl-qt-$LATEST_VERSION particl-qt
        fi

        # permission it ----------------------------------------------------------

        if [ ! -z "$SUDO_USER" ]; then
            chown -h $USER:$USER {$DOWNLOAD_FILE,${DOWNLOAD_FILE}.DIGESTS.txt,particl-cli,particld,particl-qt,particl*$LATEST_VERSION}
        fi

        # purge it ---------------------------------------------------------------

        rm -rf particl-$LATEST_VERSION

        # punch it ---------------------------------------------------------------

        pending " --> ${messages["launching"]} particld... "
        $INSTALL_DIR/particld -daemon 2>&1> /dev/null
        ok "${messages["done"]}"

        # probe it ---------------------------------------------------------------

        pending " --> ${messages["waiting_for_particld_to_respond"]}"
        echo -en "${C_YELLOW}"
        PARTYD_RUNNING=1
        while [ $PARTYD_RUNNING == 1 ] && [ $PARTYD_RESPONDING == 0 ]; do
            echo -n "."
            _check_particld_state
            sleep 5
        done
        if [ $PARTYD_RUNNING == 0 ]; then
            die "\n - particld unexpectedly quit. ${messages["exiting"]}"
        fi
        ok "${messages["done"]}"

        # poll it ----------------------------------------------------------------

        _get_versions

        # pass or punt -----------------------------------------------------------

        if [ $LATEST_VERSION == $CURRENT_VERSION ]; then
            echo -e ""
            echo -e "${C_GREEN}${messages["successfully_upgraded"]} ${LATEST_VERSION}$C_NORM"

            echo -e ""
            echo -e "${C_GREEN}${messages["installed_in"]} ${INSTALL_DIR}$C_NORM"
            echo -e ""
            ls -l --color {$DOWNLOAD_FILE,${DOWNLOAD_FILE}.DIGESTS.txt,particl-cli,particld,particl-qt,particl*$LATEST_VERSION}
            echo -e ""

	    quit
        else
            echo -e "${C_RED}${messages["particl_version"]} $CURRENT_VERSION ${messages["is_not_uptodate"]} ($LATEST_VERSION) ${messages["exiting"]}$C_NORM"
        fi
    else
        echo -e ""
        echo -e "${C_GREEN}${messages["particl_version"]} $CURRENT_VERSION ${messages["is_uptodate"]} ($LATEST_VERSION) ${messages["exiting"]}$C_NORM"
    fi
    exit 0
}

stakingnode_walletinit(){

    echo $PARTYD_WALLET
    if [ $PARTYD_RUNNING == 1 ] && [ $PARTYD_WALLETSTATUS != "Locked" ]; then
	pending " --> ${messages["stakingnode_init_walletcheck"]}"
	if [ ! $PARTYD_WALLET  == "null" ]; then
            die "\n - wallet already exists - 'partyman stakingnode' to view list of current staking node public keys or 'partyman stakingnode new' to create a new staking node public key. ${messages["exiting"]}"
	else
	    ok "${messages["done"]}"
	fi

	echo
        pending " --> ${messages["stakingnode_init_walletgenerate"]}"
	MNEMONIC=$( $PARTY_CLI mnemonic new | grep mnemonic | cut -f2 -d":" | sed 's/\ "//g' | sed 's/\",//g' )
	MNEMONIC_COUNT=$(echo "$MNEMONIC" | wc -w)
	if [ $MNEMONIC_COUNT == 24 ]; then 
	    highlight "$MNEMONIC"
	else
	    exit 1
	fi

	echo
	warn "Have you written down your recovery phrase?"
        if ! confirm " [${C_GREEN}y${C_NORM}/${C_RED}N${C_NORM}] $C_CYAN"; then
            echo -e "${C_RED}${messages["exiting"]}$C_NORM"
            echo ""
            exit 0
        fi

	pending " --> ${messages["stakingnode_init_walletcreate"]}"
	if $PARTY_CLI extkeyimportmaster "$MNEMONIC" 2>&1 >/dev/null; then
            ok "${messages["done"]}"
	else
	    die "\n - failed to create new wallet ${messages["exiting"]}"
	fi
    else
        die "\n - wallet is locked! Please unlock first. ${messages["exiting"]}"
    fi

    echo
    echo -e "    ${C_YELLOW}partyman stakingnode info$C_NORM"
    echo

}

stakingnode_newpublickey(){

    if [ $PARTYD_RUNNING == 1 ] && [ $PARTYD_WALLETSTATUS != "Locked" ]; then
        pending " --> ${messages["stakingnode_init_walletcheck"]}"
        if [ ! $PARTYD_WALLET  == "null" ]; then
	    ok "${messages["done"]}"
	else
            die "\n - no wallet exists, please type 'partyman stakingnode init' ${messages["exiting"]}"
        fi
        if [ $PARTYD_TBALANCE > 0 ]; then
            die "\n - WOAH holdup! you cannot setup coldstaking on a hotstaking wallet! ${messages["exiting"]}"
        fi

        echo

	pending "Create new staking node public key?"
        if ! confirm " [${C_GREEN}y${C_NORM}/${C_RED}N${C_NORM}] $C_CYAN"; then
            echo -e "${C_RED}${messages["exiting"]}$C_NORM"
            echo ""
            exit 0
        fi

        pending "Label for new key : "
	read pubkeylabel

	echo
        pending " --> ${messages["stakingnode_new_publickey"]}"
	if $PARTY_CLI getnewextaddress "stakingnode_$pubkeylabel"; then
            ok ""
        else
            die "\n - error creating new staking node public key! ' ${messages["exiting"]}"
        fi
    else
        die "\n - wallet is locked! Please unlock first. ${messages["exiting"]}"
    fi


}

stakingnode_rewardaddress(){

    if [ $PARTYD_RUNNING == 1 ] && [ $PARTYD_WALLETSTATUS != "Locked" ]; then
        pending " --> ${messages["stakingnode_init_walletcheck"]}"
        if [ ! $PARTYD_WALLET  == "null" ]; then
            ok "${messages["done"]}"
        else
            die "\n - no wallet exists, please type 'partyman stakingnode init' ${messages["exiting"]}"
        fi
        if [ $PARTYD_TBALANCE > 0 ]; then
            die "\n -  WOAH holdup! you cannot setup coldstaking on a hotstaking wallet! ${messages["exiting"]}"
        fi
        echo

        pending " --> ${messages["stakingnode_reward_check"]}"
	CHECK_REWARD_ADDRESS=$($PARTY_CLI walletsettings stakingoptions | jq -r .stakingoptions)
	if [ ! "$CHECK_REWARD_ADDRESS" == "default" ] ; then 
	    REWARD_ADDRESS=$($PARTY_CLI walletsettings stakingoptions | jq -r .stakingoptions.rewardaddress)
	    REWARD_ADDRESS_DATE=$($PARTY_CLI walletsettings stakingoptions | jq -r .stakingoptions.time)
	    REWARD_ADDRESS_DATEFORMATTED=$(stamp2date $REWARD_ADDRESS_DATE)
            ok "${messages["done"]}"
            pending " --> ${messages["stakingnode_reward_found"]}"
            highlight "$REWARD_ADDRESS (Set on $REWARD_ADDRESS_DATEFORMATTED)"
	else
	    ok "${messages["done"]}"
            pending " --> ${messages["stakingnode_reward_found"]}"
	    highlight "default mode"
	    echo -e "** Your wallet is configured in default mode - it will send the staking rewards back to the staking address."
	fi

	echo
        pending "Configure a new reward address?"
        if ! confirm " [${C_GREEN}y${C_NORM}/${C_RED}N${C_NORM}] $C_CYAN"; then
            echo -e "${C_RED}${messages["exiting"]}$C_NORM"
            echo ""
            exit 0
        fi

        pending "Particl Address to send all rewards to : "
        read rewardAddress

        echo
        pending " --> ${messages["stakingnode_reward_address"]}"
	echo
        if $PARTY_CLI walletsettings stakingoptions "{\"rewardaddress\":\"$rewardAddress\"}"; then
            ok ""
        else
            die "\n - error setting the reward address! ' ${messages["exiting"]}"
        fi
    else
        die "\n - wallet is locked! Please unlock first. ${messages["exiting"]}"
    fi


}


stakingnode_info(){

    if [ $PARTYD_RUNNING == 1 ] && [ $PARTYD_WALLETSTATUS != "Locked" ]; then
        pending " --> ${messages["stakingnode_init_walletcheck"]}"
        if [ ! $PARTYD_WALLET  == "null" ]; then
            ok "${messages["done"]}"
        else
            die "\n - no wallet exists, please type 'partyman stakingnode init' ${messages["exiting"]}"
        fi

        ACCOUNTID=$( $PARTY_CLI extkey account | grep "\"id"\" | cut -f2 -d":" | sed 's/\ "//g' | sed 's/\",//g' )

	echo
	FOUNDSTAKINGNODEKEY=0
	for ID in $ACCOUNTID;
	do
            IDINFO=$($PARTY_CLI extkey key $ID true 2>&-)
	    IDINFO_LABEL=$( echo $IDINFO | jq -r .label)
	    if echo $IDINFO_LABEL | grep -q "stakingnode"; then
	    	IDINFO_PUBKEY=$( echo $IDINFO | jq -r .epkey)
                pending " --> Staking Node Label : "
                ok $IDINFO_LABEL
		pending " --> Staking Node Public Key : "
	    	ok $IDINFO_PUBKEY
		echo
		FOUNDSTAKINGNODEKEY=1
	    fi
	done

        if [ $FOUNDSTAKINGNODEKEY == 0 ] || [ -z $FOUNDSTAKINGNODEKEY ]; then
            die " - no staking node public keys found, please type 'partyman stakingnode new' to create one. ${messages["exiting"]}"
        fi
    else
        die "\n - wallet is locked! Please unlock first. ${messages["exiting"]}"
    fi

}

stakingnode_stats(){

    if [ $PARTYD_RUNNING == 1 ] && [ $PARTYD_WALLETSTATUS != "Locked" ]; then
        pending " --> ${messages["stakingnode_init_walletcheck"]}"
        if [ ! $PARTYD_WALLET  == "null" ]; then
            ok "${messages["done"]}"
        else
            die "\n - no wallet exists, please type 'partyman stakingnode init' ${messages["exiting"]}"
        fi
        if [ ! $LATEST_VERSION == $CURRENT_VERSION ]; then
            die "\n - please upgrade to the latest version! ${messages["exiting"]}"
        fi

        DATE=$(date -u +%d-%m-%Y)
        DAY=$(date -u +%d)
        MONTH=$(date -u +%m)
        YEAR=$(date -u +%Y)

        COUNTER=1

        pending " --> ${messages["stakingnode_stats_daily"]}"
        ok "${messages["done"]}"
        echo
        printf '%-4s %-15s %-30s %-12s\n' \
        "${messages["stakingnode_stats_indent"]}" "DAY" "# STAKES" "TOTAL STAKED"

        until [ $COUNTER -gt $DAY ]; do
            NUMBER_OF_STAKES=$( $PARTY_CLI filtertransactions "{\"from\":\"$YEAR-$MONTH-$COUNTER\", \"to\":\"$YEAR-$MONTH-$COUNTER\",\"count\":100000,\"category\":\"stake\",\"collate\":true,\"include_watchonly\":true,\"with_reward\":true}" | jq .collated.records)
            STAKE_AMOUNT=$( $PARTY_CLI filtertransactions "{\"from\":\"$YEAR-$MONTH-$COUNTER\", \"to\":\"$YEAR-$MONTH-$COUNTER\",\"count\":100000,\"category\":\"stake\",\"collate\":true,\"include_watchonly\":true,\"with_reward\":true}" | jq .collated.total_reward)

            printf '%-4s %-15s %-30s %-12s\n' \
            "${messages["stakingnode_stats_indent"]}" "$COUNTER" "$NUMBER_OF_STAKES" "$STAKE_AMOUNT"
	    COUNTER=$((COUNTER+1))
        done

        echo
        pending " --> ${messages["stakingnode_stats_monthly"]}"
        ok "${messages["done"]}"
        echo
        printf '%-4s %-15s %-30s %-12s\n' \
        "${messages["stakingnode_stats_indent"]}" "MONTH" "# STAKES" "TOTAL STAKED"

        COUNTER=12
        until [ $COUNTER == 0 ]; do
            NUMBER_OF_STAKES=$( $PARTY_CLI filtertransactions "{\"from\":\"$YEAR-$COUNTER\", \"to\":\"$YEAR-$COUNTER\",\"count\":100000,\"category\":\"stake\",\"collate\":true,\"include_watchonly\":true,\"with_reward\":true}" | jq .collated.records)
            STAKE_AMOUNT=$( $PARTY_CLI filtertransactions "{\"from\":\"$YEAR-$COUNTER\", \"to\":\"$YEAR-$COUNTER\",\"count\":100000,\"category\":\"stake\",\"collate\":true,\"include_watchonly\":true,\"with_reward\":true}" | jq .collated.total_reward)
            if [[ $NUMBER_OF_STAKES != 0 ]] && [[ $STAKE_AMOUNT != 0 ]]; then
                printf '%-4s %-15s %-30s %-12s\n' \
                "${messages["stakingnode_stats_indent"]}" "$COUNTER" "$NUMBER_OF_STAKES" "$STAKE_AMOUNT"
            fi
            COUNTER=$((COUNTER-1))
        done

        echo
        COUNTER=12
        YEAR=2017
        until [ $COUNTER == 0 ]; do
            NUMBER_OF_STAKES=$( $PARTY_CLI filtertransactions "{\"from\":\"$YEAR-$COUNTER\", \"to\":\"$YEAR-$COUNTER\",\"count\":100000,\"category\":\"stake\",\"collate\":true,\"include_watchonly\":true,\"with_reward\":true}" | jq .collated.records)
            STAKE_AMOUNT=$( $PARTY_CLI filtertransactions "{\"from\":\"$YEAR-$COUNTER\", \"to\":\"$YEAR-$COUNTER\",\"count\":100000,\"category\":\"stake\",\"collate\":true,\"include_watchonly\":true,\"with_reward\":true}" | jq .collated.total_reward)
            if [[ $NUMBER_OF_STAKES != 0 ]] && [[ $STAKE_AMOUNT != 0 ]]; then
                printf '%-4s %-15s %-30s %-12s\n' \
                "${messages["stakingnode_stats_indent"]}" "$COUNTER ($YEAR)" "$NUMBER_OF_STAKES" "$STAKE_AMOUNT"
            fi
            COUNTER=$((COUNTER-1))
        done

    else
        die "\n - wallet is locked! Please unlock first. ${messages["exiting"]}"
    fi

}

configure_firewall(){

    UFW_STATUS=$(sudo ufw status | head -n 1 | cut -d' ' -f2)
    pending " --> ${messages["firewall_status"]}"
    ok " $UFW_STATUS"

    if [ "$UFW_STATUS" == "inactive" ]; then
        echo
        pending "Configure default firewall?"
        if ! confirm " [${C_GREEN}y${C_NORM}/${C_RED}N${C_NORM}] $C_CYAN"; then
            echo -e "${C_RED}${messages["exiting"]}$C_NORM"
            echo ""
            exit 0
        fi

        pending " --> ${messages["firewall_configure"]}"
	echo
	SSH_PORT=$(echo ${SSH_CLIENT##* })
	if [ -z "$SSH_PORT" ] ; then SSH_PORT=22 ; fi 

        # creates a minimal set of firewall rules that allows INBOUND masternode p2p & SSH ports */
	# disallow everything except ssh, 8080 (webserver) and inbound ports 51738 and 51938
	$FIREWALL_CLI default deny
	$FIREWALL_CLI logging on
	$FIREWALL_CLI allow $SSH_PORT/tcp
        $FIREWALL_CLI allow 8080/tcp comment 'partyman webserver'
	$FIREWALL_CLI allow 51738/tcp comment 'particl p2p mainnet'
        $FIREWALL_CLI allow 51938/tcp comment 'particl p2p testnet'

	# This will only allow 6 connections every 30 seconds from the same IP address.
	$FIREWALL_CLI limit OpenSSH
	$FIREWALL_CLI --force enable
        ok "${messages["done"]}"
    fi

        pending " --> ${messages["firewall_report"]}"
	echo
	$FIREWALL_CLI status
}

firewall_reset(){

    UFW_STATUS=$(sudo ufw status | head -n 1 | cut -d' ' -f2)
    pending " --> ${messages["firewall_status"]}"
    ok " $UFW_STATUS"

    if [ "$UFW_STATUS" == "active" ]; then
        echo
        pending "Reset and disable firewall?"
        if ! confirm " [${C_GREEN}y${C_NORM}/${C_RED}N${C_NORM}] $C_CYAN"; then
            echo -e "${C_RED}${messages["exiting"]}$C_NORM"
            echo ""
            exit 0
        fi

	ok ""
        echo "y" | $FIREWALL_CLI reset
        UFW_STATUS=$(sudo ufw status | head -n 1 | cut -d' ' -f2)
        pending " --> ${messages["firewall_status"]}"
        ok " $UFW_STATUS"
    fi
}

_get_particld_proc_status(){
    PARTYD_HASPID=0
    if [ -e $INSTALL_DIR/particld.pid ] ; then
        PARTYD_HASPID=`ps --no-header \`cat $INSTALL_DIR/particld.pid 2>/dev/null\` | wc -l`;
    else
        PARTYD_HASPID=$(pidof particld)
        if [ $? -gt 0 ]; then
            PARTYD_HASPID=0
        fi
    fi
    PARTYD_PID=$(pidof particld)
}

get_particld_status(){

    _get_particld_proc_status

    PARTYD_UPTIME=`$PARTY_CLI uptime 2>/dev/null`
    if [ -z "$PARTYD_UPTIME" ] ; then PARTYD_UPTIME=0 ; fi

    PARTYD_LISTENING=`netstat -nat | grep LIST | grep 51738 | wc -l`;
    PARTYD_CONNECTIONS=`netstat -nat | grep ESTA | grep 51738 | wc -l`;
    PARTYD_CURRENT_BLOCK=`$PARTY_CLI getblockcount 2>/dev/null`
    if [ -z "$PARTYD_CURRENT_BLOCK" ] ; then PARTYD_CURRENT_BLOCK=0 ; fi


    WEB_BLOCK_COUNT_CHAINZ=$($curl_cmd https://chainz.cryptoid.info/part/api.dws?q=getblockcount 2>/dev/null | jq -r .);
    if [ -z "$WEB_BLOCK_COUNT_CHAINZ" ]; then
        WEB_BLOCK_COUNT_CHAINZ=0
    fi

    WEB_BLOCK_COUNT_PART=$($curl_cmd https://explorer.particl.io/particl-insight-api/sync 2>/dev/null | jq -r .blockChainHeight)
    if [ -z "$WEB_BLOCK_COUNT_PART" ]; then
        WEB_BLOCK_COUNT_PART=0
    fi

    PARTYD_SYNCED=0
    if [ $PARTYD_RUNNING == 1 ]; then
        if [ $PARTYD_CURRENT_BLOCK == $WEB_BLOCK_COUNT_CHAINZ ] || [ $PARTYD_CURRENT_BLOCK == $WEB_BLOCK_COUNT_PART ] || [ $PARTYD_CURRENT_BLOCK -ge $WEB_BLOCK_COUNT_CHAINZ -5 ] || [ $PARTYD_CURRENT_BLOCK -ge $WEB_BLOCK_COUNT_PART -5 ]; then
            PARTYD_SYNCED=1
        fi
    fi

    PARTYD_CONNECTED=0
    if [ $PARTYD_CONNECTIONS -gt 0 ]; then PARTYD_CONNECTED=1 ; fi

    PARTYD_UP_TO_DATE=0
    if [ -z "$LATEST_VERSION" ]; then
        PARTYD_UP_TO_DATE_STATUS="UNKNOWN"
    else
        PARTYD_UP_TO_DATE_STATUS="NO"
        if [ $LATEST_VERSION == $CURRENT_VERSION ]; then
            PARTYD_UP_TO_DATE=1
        fi
    fi

    get_public_ips

    PUBLIC_PORT_CLOSED=$( timeout 2 nc -4 -z $PUBLIC_IPV4 51738 2>&1 >/dev/null; echo $? )

    #staking info
    if [ $PARTYD_RUNNING == 1 ]; then
    	PARTYD_GETSTAKINGINFO=`$PARTY_CLI getstakinginfo 2>/dev/null`;
	STAKING_ENABLED=$(echo "$PARTYD_GETSTAKINGINFO" | grep enabled | awk '{print $2}' | sed -e 's/[",]//g')
    	STAKING_CURRENT=$(echo "$PARTYD_GETSTAKINGINFO" | grep staking | awk '{print $2}' | sed -e 's/[",]//g')
    	STAKING_STATUS=$(echo "$PARTYD_GETSTAKINGINFO" | grep cause | awk '{print $2}' | sed -e 's/[",]//g')
    	STAKING_PERCENTAGE=$(echo "$PARTYD_GETSTAKINGINFO" | grep percentyearreward | awk '{print $2}' | sed -e 's/[",]//g')
    	STAKING_DIFF=$(echo "$PARTYD_GETSTAKINGINFO" | grep difficulty | awk '{print $2}' | sed -e 's/[",]//g')
    	PARTYD_STAKEWEIGHT=$(echo "$PARTYD_GETSTAKINGINFO" | grep "\"weight"\" | awk '{print $2}' | sed -e 's/[",]//g')
    	PARTYD_NETSTAKEWEIGHT=$(echo "$PARTYD_GETSTAKINGINFO" | grep netstakeweight | awk '{print $2}' | sed -e 's/[",]//g')

        PARTYD_NETSTAKEWEIGHT=$(($PARTYD_NETSTAKEWEIGHT / 100000000))
        PARTYD_STAKEWEIGHT=$(($PARTYD_STAKEWEIGHT / 100000000))

	#Hack for floating point arithmetic 
        STAKEWEIGHTPERCENTAGE=$( awk "BEGIN {printf \"%.3f%%\", $PARTYD_STAKEWEIGHT/$PARTYD_NETSTAKEWEIGHT*100}" )
	T_PARTYD_STAKEWEIGHT=$(printf "%'.0f" $PARTYD_STAKEWEIGHT)
        PARTYD_STAKEWEIGHTLINE="$T_PARTYD_STAKEWEIGHT ($STAKEWEIGHTPERCENTAGE)"

        PARTYD_GETCOLDSTAKINGINFO=`$PARTY_CLI getcoldstakinginfo 2>/dev/null`;
        CSTAKING_ENABLED=$(echo "$PARTYD_GETCOLDSTAKINGINFO" | grep enabled | awk '{print $2}' | sed -e 's/[",]//g')
        CSTAKING_CURRENT=$(echo "$PARTYD_GETCOLDSTAKINGINFO" | grep currently_staking | awk '{print $2}' | sed -e 's/[",]//g')
        CSTAKING_BALANCE=$(echo "$PARTYD_GETCOLDSTAKINGINFO" | grep coin_in_coldstakeable_script | awk '{print $2}' | sed -e 's/[",]//g')
    fi
}

date2stamp () {
    date --utc --date "$1" +%s
}

stamp2date (){
    date --utc --date "1970-01-01 $1 sec" "+%Y-%m-%d %T"
}

dateDiff (){
    case $1 in
        -s)   sec=1;      shift;;
        -m)   sec=60;     shift;;
        -h)   sec=3600;   shift;;
        -d)   sec=86400;  shift;;
        *)    sec=86400;;
    esac
    dte1=$(date2stamp $1)
    dte2=$(date2stamp "$2")
    diffSec=$((dte2-dte1))
    if ((diffSec < 0)); then abs=-1; else abs=1; fi
    echo $((diffSec/sec*abs))
}

function displaytime()
{
    local t=$1

    local d=$((t/60/60/24))
    local h=$((t/60/60%24))
    local m=$((t/60%60))
    local s=$((t%60))

    if [[ $d > 0 ]]; then
            [[ $d = 1 ]] && echo -n "$d day " || echo -n "$d days "
    fi
    if [[ $h > 0 ]]; then
            [[ $h = 1 ]] && echo -n "$h hour " || echo -n "$h hours "
    fi
    if [[ $m > 0 ]]; then
            [[ $m = 1 ]] && echo -n "$m minute " || echo -n "$m minutes "
    fi
    if [[ $d = 0 && $h = 0 && $m = 0 ]]; then
            [[ $s = 1 ]] && echo -n "$s second" || echo -n "$s seconds"
    fi
    echo
}

get_host_status(){
    HOST_LOAD_AVERAGE=$(cat /proc/loadavg | awk '{print $1" "$2" "$3}')
    uptime=$(</proc/uptime)
    uptime=${uptime%%.*}
    HOST_UPTIME_DAYS=$(( uptime/60/60/24 ))
    HOSTNAME=$(hostname -f)
}


print_getinfo() {

    if [ $PARTYD_RUNNING == 1 ]; then
	$PARTY_CLI -getinfo
	$PARTY_CLI getwalletinfo
    fi
}

print_status() {

    pending "${messages["status_hostnam"]}" ; ok "$HOSTNAME"
    pending "${messages["status_uptimeh"]}" ; ok "$HOST_UPTIME_DAYS ${messages["days"]}, $HOST_LOAD_AVERAGE"
    pending "${messages["status_particldip"]}" ; [ $PUBLIC_IPV4 != 'none' ] && ok "$PUBLIC_IPV4" || err "$PUBLIC_IPV4"
    pending "${messages["status_particldve"]}" ; ok "$CURRENT_VERSION"
    pending "${messages["status_uptodat"]}" ; [ $PARTYD_UP_TO_DATE -gt 0 ] && ok "${messages["YES"]}" || err "$PARTYD_UP_TO_DATE_STATUS ($LATEST_VERSION)"
    pending "${messages["status_running"]}" ; [ $PARTYD_HASPID     -gt 0 ] && ok "${messages["YES"]}" || err "${messages["NO"]}"
    pending "${messages["status_uptimed"]}" ; [ $PARTYD_UPTIME    -gt 0 ] && ok "$(displaytime $PARTYD_UPTIME)" || err "${messages["NO"]}"
    pending "${messages["status_drespon"]}" ; [ $PARTYD_RUNNING    -gt 0 ] && ok "${messages["YES"]}" || err "${messages["NO"]}"
    pending "${messages["status_dlisten"]}" ; [ $PARTYD_LISTENING  -gt 0 ] && ok "${messages["YES"]}" || err "${messages["NO"]}"
    pending "${messages["status_dportop"]}" ; [ $PUBLIC_PORT_CLOSED  -lt 1 ] && ok "${messages["YES"]}" || highlight "${messages["NO"]}*"
    pending "${messages["status_dconnec"]}" ; [ $PARTYD_CONNECTED  -gt 0 ] && ok "${messages["YES"]}" || err "${messages["NO"]}"
    pending "${messages["status_dconcnt"]}" ; [ $PARTYD_CONNECTIONS   -gt 0 ] && ok "$PARTYD_CONNECTIONS" || err "$PARTYD_CONNECTIONS"
    pending "${messages["status_dblsync"]}" ; [ $PARTYD_SYNCED     -gt 0 ] && ok "${messages["YES"]}" || err "${messages["NO"]}"
    pending "${messages["status_dbllast"]}" ; [ $PARTYD_SYNCED     -gt 0 ] && ok "$PARTYD_CURRENT_BLOCK" || err "$PARTYD_CURRENT_BLOCK"
    pending "${messages["status_webpart"]}" ; [ $WEB_BLOCK_COUNT_PART -gt 0 ] && ok "$WEB_BLOCK_COUNT_PART" || err "$WEB_BLOCK_COUNT_PART"
    pending "${messages["status_webchai"]}" ; [ $WEB_BLOCK_COUNT_CHAINZ -gt 0 ] && ok "$WEB_BLOCK_COUNT_CHAINZ" || err "$WEB_BLOCK_COUNT_CHAINZ"
    if [ $PARTYD_RUNNING == 1 ]; then
    	pending "${messages["breakline"]}" ; ok ""
    	pending "${messages["status_stakeen"]}" ; [ $STAKING_ENABLED -gt 0 ] && ok "${messages["YES"]} - $STAKING_PERCENTAGE%" || err "${messages["NO"]}"
        pending "${messages["status_stakedi"]}" ; ok $(printf "%'.0f" $STAKING_DIFF)
        pending "${messages["status_stakenw"]}" ; ok $(printf "%'.0f" $PARTYD_NETSTAKEWEIGHT)
	pending "${messages["breakline"]}" ; ok ""
    	pending "${messages["status_stakecu"]}" ; [ $STAKING_CURRENT -gt 0 ] && ok "${messages["YES"]}" || err "${messages["NO"]} - "$STAKING_STATUS
        pending "${messages["status_stakeww"]}" ; ok "$PARTYD_STAKEWEIGHTLINE"
        pending "${messages["status_stakebl"]}" ; ok $(printf "%'.0f" $CSTAKING_BALANCE)

    fi

    if [ $PUBLIC_PORT_CLOSED  -gt 0 ]; then
       echo
       highlight "* Inbound P2P Port is not open - this is okay and will not affect the function of this staking node."
       highlight "  However by opening port 51738/tcp you can provide full resources to the Particl Network by acting as a 'full node'."
       highlight "  A 'full staking node' will increase the number of other nodes you connect to beyond the 16 limit."
    fi
}

show_message_configure() {
    echo
    ok "${messages["to_start_particl"]}"
    echo
    echo -e "    ${C_YELLOW}partyman restart now$C_NORM"
    echo
}

get_public_ips() {
    PUBLIC_IPV4=$(dig +short myip.opendns.com @resolver1.opendns.com)
}
