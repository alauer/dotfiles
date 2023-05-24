## USE LIKE THIS:
# source <(curl -ksS https://gitlab.corp.amdocs.com/ansible-roles/image-template/raw/master/files/profile_proxy.sh)
# proxy install  # for install in /etc/profile.d/
# proxy on       # to run on|off|install
########
### CORE FUNCTIONALITY:
function proxy
switch $argv[1]
case a auto
    proxyauto
case af auto_full install reinstall 
    proxy_install_in_profile_auto; and proxyauto; and proxy_os_configs_auto; and proxyauto; and echo "check using: proxy status"
case c proxy_os_configs_auto
    proxy_os_configs_auto
case on ON On
    proxyon $2
case off OFF Off
    proxyoff
case s status 
    proxystatus
case install_in_profile
    proxy_install_in_profile
case force_on full on_force
    proxyon; and proxy_os_configs_on; and proxy_install_in_profile_on; and proxystatus
case help
    proxyhelp
case '*'
    proxyon $1
end
end

## Test if we are in WSL
function is_wsl
set MS_IN_UNAME (uname -r | grep -i microsoft || true )
if test "x$WSL_DISTRO_NAME" != "x"  -o -d /run/WSL/ -o "x$MS_IN_UNAME" != "x"
    echo "1"
else
    echo "0"
end
end

## Test if we are in docker
function is_docker
if test -e /sbin/docker-init
    echo "1"
else
    echo "0"
end
end

## Test if the selected proxy is reachable
function is_proxy_reachable
set PROXY_IS_REACHABLE 0
set DIG_PARAMS " " # not working in ZSH
  #NC_PARAMS="-v -4 -w2 -z" #not working in zsh
  #PROXY_URL=$(set +eu ; echo ${1:-"genproxy.corp.amdocs.com:8080"} ) #removed
  #moving from genproxy to 10.x. as sometimes the DNS resolving does not work...
set ARG1 (set +eu ; echo $argv[1]"x")

if test "${ARG1}" != "x"
    ## Backup solution, when is_proxy_reachable is called without a param
if test is_wsl = "1"
    set PINGHOSTIP "wslproxy.corp.amdocs.com"
else
    set PINGHOSTIP "10.24.1.121" # aka "genproxy.corp.amdocs.com" ISR
    set DIG_PARAMS " -x " # not working in zsh...
end
end

  ###export PINGHOSTIP="${1}:8080" # not always IP, param could come also as a name to be resolved...

  set PROXY_URL (set +eu ; echo ${1:-"$PINGHOSTIP:8080"} )
  PROXY_HOST=$(echo $PROXY_URL | cut -d":" -f1 )
  PROXY_PORT=$(echo $PROXY_URL | cut -d":" -f2 )
  ## test if genproxycan be reached
  # nc is much better, as the ping is both slow 
  # also some users don't have perms to run ping.

  # if the nc binary exists, we'll use it instead of ping
  NC_EXISTS=$( { type nc 2>/dev/null || true ; } | { grep -c " is " || true ; } )

  DIG_EXISTS=$( { type dig 2>/dev/null || true ; } | { grep -c " is " || true ; } )

  ## on mac, we cannot use dig <ip-address>, so our dig solution should be avoided here, and shifting to NC or PING.
  ON_MAC=0
  if [ \( -s /etc/bashrc_Apple_Terminal \) ]; then
    ON_MAC=1
  fi
  if [ $ON_MAC -lt 1 -a $DIG_EXISTS -gt "0" ]; then
  #if [ $DIG_EXISTS -gt "0" ]; then
    DIG_RESOLVED=$({ dig +short +tries=1 +time=1 +search `echo $DIG_PARAMS` $PROXY_HOST 2>/dev/null || true ; } | { grep -v " timed out" || true ; } | { grep -v "no servers could be reached" || true ; } |  { grep '\.' || true ; } | { wc -l || true ; } )  # Not working in ZSH due to $DIG_PARAMS
    #DIG_RESOLVED=$({ dig +short +tries=1 +time=1 +search $PROXY_HOST 2>/dev/null || true ; } | { grep -v " timed out" || true ; } | { grep -v "no servers could be reached" || true ; } |  { grep '\.' || true ; } | { wc -l || true ; } )
    [ $DIG_RESOLVED -gt "0" ] && PROXY_IS_REACHABLE=1
  elif [ $NC_EXISTS -gt "0" ]; then
   while true; do # this should run only once; It's usefull to skip other tests if one shows there is no proxy
    CONN_TIMEDOUT=$({ nc -v -4 -w2 -z $PROXY_HOST $PROXY_PORT 2>&1 || true ; } | { grep -c 'timed out' || true ; } )
    [ $CONN_TIMEDOUT -eq "1" ] && PROXY_IS_REACHABLE=0 && break
    CONN_REFUSED=$({ nc -v -4 -w2 -z $PROXY_HOST $PROXY_PORT 2>&1 || true ; } | { grep -c efused || true ; } )
    [ $CONN_REFUSED -eq "1" ] && PROXY_IS_REACHABLE=0 && break
    NAME_RESOLUTION_ISSUE=$({ nc -v -4 -w2 -z $PROXY_HOST $PROXY_PORT 2>&1 || true ; } | { grep -c -i name || true ; } )
    [ $NAME_RESOLUTION_ISSUE -eq "1" ] && PROXY_IS_REACHABLE=0 && break
    #let SOME_ERROR=CONN_TIMEDOUT+CONN_REFUSED+NAME_RESOLUTION_ISSUE
    #if [ $SOME_ERROR -gt "0" ]; then
    #  PROXY_IS_REACHABLE=0
    #else
    #  PROXY_IS_REACHABLE=1
    #fi
    PROXY_IS_REACHABLE=1
    break
   done
  else
    # fallback to using ping, as nc was not found. One should install nc asap, to ensure correct results.
    P=$( { ping -4 -q -n -c 2 -W 1 -w 2 $PROXY_HOST 2>/dev/null || true ; } | { grep -c " 0% packet loss" || true ; } )
    if [ $P -eq "1" ]; then
      PROXY_IS_REACHABLE=1
    else
      PROXY_IS_REACHABLE=0
    fi
  fi

  #return $PROXY_IS_REACHABLE
  #we cannot return non-zero as it conflicts with set -e
  echo "$PROXY_IS_REACHABLE"
end