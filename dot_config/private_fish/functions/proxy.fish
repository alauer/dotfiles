## USE LIKE THIS:
# source <(curl -ksS https://gitlab.corp.amdocs.com/ansible-roles/image-template/raw/master/files/profile_proxy.sh)
# proxy install  # for install in /etc/profile.d/
# proxy on       # to run on|off|install
########
### CORE FUNCTIONALITY:
function proxy
  switch $argv[1]
    case "" "a" "auto"
      proxyauto
    case "af" "auto_full" "install" "reinstall"
      proxy_install_in_profile_auto
      proxyauto
      proxy_os_configs_auto
      proxyauto
      echo "check using: proxy status"
    case "c" "proxy_os_configs_auto"
      proxy_os_configs_auto
    case "on" "ON" "On"
      proxyon $argv[2]
    case "off" "OFF" "Off"
      proxyoff
    case "s" "status"
      proxystatus
    case "install_in_profile"
      proxy_install_in_profile
    case "force_on" "full" "on_force"
      proxyon
      proxy_os_configs_on
      proxy_install_in_profile_on
      proxystatus
    case "help"
      proxyhelp
    case "*"
      proxyon $argv[1]
  end
end

## Test if we are in WSL
function is_wsl
  set MS_IN_UNAME (uname -r | grep -i microsoft || true )
  if [ "x$WSL_DISTRO_NAME" != "x"  -o -d /run/WSL/ -o "x$MS_IN_UNAME" != "x" ]
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
set ARG1 (echo $argv[1]"x")

if test $ARG1 != "x"
    ## Backup solution, when is_proxy_reachable is called without a param
if test is_wsl = "1"
    set -x PINGHOSTIP "wslproxy.corp.amdocs.com"
else
    set -x PINGHOSTIP "10.24.1.121" # aka "genproxy.corp.amdocs.com" ISR
    set DIG_PARAMS " -x " # not working in zsh...
end
end

  ###export PINGHOSTIP="${1}:8080" # not always IP, param could come also as a name to be resolved...

  #set PROXY_URL (echo (1:-"$PINGHOSTIP:8080") )
  set -l PROXY_URL (echo $argv[1] $PINGHOSTIP:8080)[1]
  set PROXY_HOST (echo $PROXY_URL | cut -d":" -f1 )
  set PROXY_PORT (echo $PROXY_URL | cut -d":" -f2 )
  ## test if genproxycan be reached
  # nc is much better, as the ping is both slow 
  # also some users don't have perms to run ping.

  # if the nc binary exists, we'll use it instead of ping
  set NC_EXISTS (if type -q nc; echo 1; else; echo 0; end)
  set DIG_EXISTS (if type -q dig; echo 1; else; echo 0; end)

  ## on mac, we cannot use dig <ip-address>, so our dig solution should be avoided here, and shifting to NC or PING.
  set ON_MAC 0
  if test \( -s /etc/bashrc_Apple_Terminal \)
    set ON_MAC 1
  end
  if test $ON_MAC -lt 1 -a $DIG_EXISTS -gt "0"
    set DIG_RESOLVED ( dig +short +tries=1 +time=1 +search $DIG_PARAMS $PROXY_HOST 2>/dev/null  |  grep -v " timed out" | grep -v "no servers could be reached"  | grep '\.' | wc -l )  # Not working in ZSH due to $DIG_PARAMS
    if test $DIG_RESOLVED -gt 0; set PROXY_IS_REACHABLE 1; end
  else if test $NC_EXISTS -gt 0
   while true # this should run only once; It's usefull to skip other tests if one shows there is no proxy
    set CONN_TIMEDOUT ( nc -v -4 -w2 -z $PROXY_HOST $PROXY_PORT 2>&1  | grep -c 'timed out' )
    if test $CONN_TIMEDOUT -eq "1"; set PROXY_IS_REACHABLE 0; and break; end
    set CONN_REFUSED ( nc -v -4 -w2 -z $PROXY_HOST $PROXY_PORT 2>&1  | grep -c efused )
    if test $CONN_REFUSED -eq "1"; set PROXY_IS_REACHABLE 0; and break; end 
    set NAME_RESOLUTION_ISSUE ( nc -v -4 -w2 -z $PROXY_HOST $PROXY_PORT 2>&1  | grep -c -i name )
    if test $NAME_RESOLUTION_ISSUE -eq "1"; set PROXY_IS_REACHABLE=0; and break; end
    set PROXY_IS_REACHABLE 1
    break
   end # ends the while
  else
    # fallback to using ping, as nc was not found. One should install nc asap, to ensure correct results.
    set P ( ping -4 -q -n -c 2 -W 1 -w 2 $PROXY_HOST 2>/dev/null | grep -c " 0% packet loss" )
    if test $P -eq "1"
      set PROXY_IS_REACHABLE 1
    else
      set PROXY_IS_REACHABLE 0
    end
  end
  #return $PROXY_IS_REACHABLE
  #we cannot return non-zero as it conflicts with set -e
  echo "$PROXY_IS_REACHABLE"
end

## Every time proxy is called, we can trigger additional scripts.
function proxy_auto_triggers
  #sub-shell to save callers shell options, but working without unset
  set ARG1 (echo $argv[1]"x")
  if test $ARG1 = "x"
    return 0 ; # no arg passed, skipping triggers
  end

  set PROXY_ON_OFF_ONE_OR_ZERO $argv[1]
  
  if test -r /etc/proxy/auto_triggers/ 
    return 0 ; # there is no such folder
  end

  for i in /etc/proxy/auto_triggers/*.sh
    if test -x $i
      $i $PROXY_ON_OFF_ONE_OR_ZERO >/dev/null 2>&1; or true # no output
      #"$i" "$PROXY_ON_OFF_ONE_OR_ZERO" || true # keep output
    end
  end
end

function proxyhelp
  echo "\
proxy auto|on|off|install|reinstall|status
First time install (requires sudo). Use either curl or wget
source <(curl -kSs https://gitlab.corp.amdocs.com/ansible-roles/image-template/raw/master/files/profile_proxy.sh)
OR
source <(wget --quiet --tries=1 --timeout=2 -O - --no-check-certificate https://gitlab.corp.amdocs.com/ansible-roles/image-template/raw/master/files/profile_proxy.sh)
proxy install

afterwards, usual commands are:
proxy auto # will enable env vars proxy while in amdocs network, and disable otherwise; As opposed to auto_full, auto will not modify anything beyond env vars
proxy install # will install/reinstall and also determine if you are in office or not, and enable/disable all proxy related configurations for your linux (and requries sudo for write in /etc/profile.d/)

more details: typedef proxy OR vi /etc/profile.d/profile_proxy.sh

if you provided a custom proxy value and it is not reachable, you will see this message.
"
end

function proxy_get_url
 #no_proxy_alt can be prepared in advance in order to add to the list.
  #http://$username:$password@proxyserver:8080/

  #sub-shell to save callers shell options, but working without unset
  #ARG1=$(set +eu ; echo "${1}x" )  #set -u friendly outside
  if test $POSSIBLE_PROXY -eq "x"
    # No value provided as arg, using the default:
    if test (is_wsl) -eq "1" -o -f /etc/eaas.info
      set POSSIBLE_PROXY "wslproxy.corp.amdocs.com"
      set TMP (is_proxy_reachable "$POSSIBLE_PROXY:8080")
      if test $TMP -eq "1"
        set -x http_proxy "http://$POSSIBLE_PROXY:8080/"
      else
        set POSSIBLE_PROXY "10.232.233.204" # isrwslproxy.corp.amdocs.com # because wslproxy is not in all DNS servers (@Paul Arevalo)
        set TMP (is_proxy_reachable "$POSSIBLE_PROXY:8080")
        if [ "$TMP" = "1" ]; then
          set -x http_proxy "http://$POSSIBLE_PROXY:8080/"
        else
          set -x http_proxy "ERROR_error_Error_PROXY_proxy_URL_IS_UNREACHABLE_$POSSIBLE_PROXY"
          proxyhelp && return 76
        end
      end
    else
      set -x http_proxy "http://genproxy.corp.amdocs.com:8080/"
    end
  else ## POSSIBLE_PROXY is defined from outsite (e.g. proxyon function)
    ## first, test if it was intended to set a special servername, or it was a mistake:
    set has_dot (echo $POSSIBLE_PROXY | grep -c "\." 2>/dev/null; or true)
    if test $has_dot -eq 0
      set POSSIBLE_PROXY "$POSSIBLE_PROXY.corp.amdocs.com"
    end
    #P=$( { ping -4 -q -n -c 2 -W 1 -w 2 $POSSIBLE_PROXY 2>/dev/null || true ; } | { grep -c " 0% packet loss" || true ; } )
    if tst (is_proxy_reachable "$POSSIBLE_PROXY:8080") -eq "1"
      set -x http_proxy "http://$POSSIBLE_PROXY:8080/"
    else
      set -x http_proxy "ERROR_error_Error_PROVIDED_PROXY_proxy_URL_IS_UNREACHABLE_$POSSIBLE_PROXY"
      proxyhelp; and return 76
    end
  end
  echo $http_proxy
end

function proxyon
  #no_proxy_alt can be prepared in advance in order to add to the list.
  #http://$username:$password@proxyserver:8080/

  #sub-shell to save callers shell options, but working without unset
  set ARG1 (echo $argv[1]"x")
  if test $ARG1 != "x" #set -u friendly outside
    #export POSSIBLE_PROXY="${1}" # we got proxy as argument to proxyon
    set POSSIBLE_PROXY (echo "$argv[1]:dummyPort" | cut -d":" -f1 )
  else
    set -x POSSIBLE_PROXY "x"
  end
  set http_proxy (proxy_get_url)
  set -x http_proxy
  set -x all_proxy "$http_proxy"
  set -x ALL_PROXY "$http_proxy"
  set -x HTTP_PROXY "$http_proxy"
  set -x https_proxy "$http_proxy"
  set -x HTTPS_PROXY "$http_proxy"
  set -x ftp_proxy "$http_proxy"
  set -x FTP_PROXY "$http_proxy"
  set -x CUSTOM_NO_PROXY $CUSTOM_NO_PROXY":-localhost"
  set -x custom_no_proxy $custom_no_proxy":-localhost"
  set -x NO_PROXY "$no_proxy"
  set -x no_http_proxy "$no_proxy"
  
  # trigger proxy scripts with arg 1 (in amdocs)
  proxy_auto_triggers 1; or true
end

function proxyauto
  set TMP (is_proxy_reachable)
  if test $TMP = "1"
    proxyon
  else
    proxyoff
  end
end

function proxyoff
  for X in HTTP_PROXY http_proxy HTTPS_PROXY https_proxy FTP_PROXY ftp_proxy no_proxy NO_PROXY no_http_proxy all_proxy ALL_PROXY
    set -e X; or true
    set -e POSSIBLE_PROXY; or true
  end  
  # trigger proxy scripts with arg 1 (in amdocs)
  proxy_auto_triggers 0; true
end

function proxystatus
    echo "\
Usage: proxy <auto|on|off|status|auto_full|help> 
=== Current Status: ===
"
  for X in HTTP_PROXY http_proxy HTTPS_PROXY https_proxy FTP_PROXY ftp_proxy no_proxy NO_PROXY no_http_proxy all_proxy ALL_PROXY
    eval echo "set -x $X" "(echo $$X)"
  end
end

############################
### ADVANCED FUNCTIONALITY:#
############################
function proxy_os_configs_auto
  echo "$funcname$argv:"
  #P=$( { ping -4 -q -n -c 2 -W 1 -w 2 genproxy.corp.amdocs.com 2>/dev/null || true ; } | { grep -c " 0% packet loss" || true ; } )
  if test (is_proxy_reachable) -eq "1"
    proxy_os_configs_on
  else
    proxy_os_configs_off
  end
end

function proxy_os_configs_on
  echo "$funcname$argv:"
  if test -s /etc/bashrc_Apple_Terminal
    # MacOS
    echo "Advanced support of MacOS is not yet there, PRs welcome."
  else
    # Linux
    switch (grep ID_LIKE /etc/os-release | cut -d"=" -f2 | tr -d '"' )
    case debian
        debian_machine_wide_proxy_on
        debian_snap_proxy_on
        debian_software_manager_gui_on
        debian_nat_dns_search_domain_smart_on
        docker_proxy_on
    case fedora
        echo "RHEL/fedora based are partially supported yet. PRs welcome"
    case '*'
        echo "You see to run a cool OS, but not supported yet. PRs welcome"
    end
  end
end

function proxy_os_configs_off
echo "$funcname$argv:"
  switch (grep ID_LIKE /etc/os-release 2>/dev/null | cut -d"=" -f2 | tr -d '"' )
  case debian
      debian_machine_wide_proxy_off
      debian_snap_proxy_off
      debian_software_manager_gui_off
      debian_nat_dns_search_domain_smart_off
      docker_proxy_off
  case fedora
      echo "RHEL/fedora based are not supported yet. PRs welcome"
  case *
      echo "You see to run a cool OS, but not supported yet. PRs welcome"
  end
end

function proxy_install_in_profile_auto
echo "$funcname$argv:"
  if test (is_proxy_reachable) -eq "1"
      proxy_install_in_profile_on
  else
      echo "proxy_install_in_profile failed, please retry when connected to amdocs network and ping genproxy works "
  end
end

# Is this really needed if being managed by Chezmoi?
function proxy_install_in_profile_on
  echo "$funcname$argv:"
  set WGET_EXISTS (if type -q wget; echo 1; else; echo 0; end)
  set -x no_proxy (if set -q no_proxy; echo "$no_proxy,gitlab.corp.amdocs.com"; else; echo "localhost,gitlab.corp.amdocs.com"; end)
  set -x NO_PROXY (if set -q no_proxy; echo "$no_proxy,gitlab.corp.amdocs.com"; else; echo "localhost,gitlab.corp.amdocs.com"; end)

  if test $WGET_EXISTS -gt "0"
    rm -f /tmp/profile_proxy.sh 2>/dev/null; or true
    wget --quiet --no-check-certificate --tries=1 --timeout=2 -O /tmp/profile_proxy.sh https://gitlab.corp.amdocs.com/ansible-roles/image-template/raw/master/files/profile_proxy.sh
  else
    curl -k -Sso /tmp/profile_proxy.sh https://gitlab.corp.amdocs.com/ansible-roles/image-template/raw/master/files/profile_proxy.sh
  end
  if [ -s /tmp/profile_proxy.sh ]; then
    . /tmp/profile_proxy.sh
    if [ \( -s /etc/bashrc_Apple_Terminal \) -a \( -s /etc/profile \) ]; then
      # MacOS
      sudo mv -f /tmp/profile_proxy.sh /etc/profile_proxy.sh
      echo ". /etc/profile_proxy.sh" | sudo tee -a /etc/zprofile >/dev/null
      echo ". /etc/profile_proxy.sh" | sudo tee -a /etc/profile >/dev/null
    else
      # Linux
      sudo mv -f /tmp/profile_proxy.sh /etc/profile.d/profile_proxy.sh
    end
  else
    echo "could not download https://gitlab.corp.amdocs.com/ansible-roles/image-template/raw/master/files/profile_proxy.sh "
    #"; going to exit" && return 77 # removing this as we will have proxy auto after config. And we want to have the vars set even when this download fails.
  end
end
#####################
#####################

#########################
### docker proxy ########
#########################
function docker_proxy_on 
  echo "$funcname$argv:"
  sudo mkdir -p /etc/systemd/system/docker.service.d/ /etc/systemd/system/containerd.service.d/ /etc/systemd/system/crio.service.d/

  if test \( (is_wsl) -eq "1" \) -o \( -f /etc/eaas.info \)
    echo "(status filename) - in WSL"
    echo "\
[Service]
Environment=http_proxy=http://wslproxy.corp.amdocs.com:8080
Environment=https_proxy=http://wslproxy.corp.amdocs.com:8080
Environment=no_proxy=localhost,127.0.0.1,127.0.1.1,.svc,.default,.local,.internal,.testing,fs.amdocs.com,.amdocs.com,.sock,.neo.corp.amdocs.aws,on-nexus-proxy,nexus-proxy,aeegerrit,on-nexus3,on-nexus4,.openet-dublin,10.65.224.59,.openet.com,docker.sock,localaddress,.localdomain,.localdomain.com,illinlic01,indlinsls,linvc04,bitbucket,gitlab,ldap,10.232.233.70,10.19.50.20,10.19.50.20,genproxy,10.17.88.18,10.17.88.22,10.232.217.1,10.232.217.2,10.20.40.100,10.19.214.200,distributionstg,artifactorystg,distribution,artifactory,.socket,168.63.129.16,169.254.169.254,169.254.169.253,169.254.169.123,127.254.254.254,teleproxy,traffic-manager.ambassador,"(hostname -s),(hostname -f),(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'|tr '\n' ',')(host -4 (hostname -f) 2>/dev/null | grep '\.' | grep -v "not found" | grep -v \":\" | awk '{print $NF}' | tr '\n' ',')localhost4,"$CUSTOM_NO_PROXY","$custom_no_proxy",10.0.0.0,172.16.0.0,192.168.0.0"
" | tee /etc/systemd/system/containerd.service.d/http-proxy.conf | tee /etc/systemd/system/crio.service.d/http-proxy.conf > /etc/systemd/system/docker.service.d/docker_proxy.conf
  else
    echo "(status filename) - not in WSL"
    echo "\
[Service]
Environment=http_proxy=http://genproxy.corp.amdocs.com:8080
Environment=https_proxy=http://genproxy.corp.amdocs.com:8080
Environment=no_proxy=localhost,127.0.0.1,127.0.1.1,.svc,.default,.local,.internal,.testing,fs.amdocs.com,.amdocs.com,.sock,.neo.corp.amdocs.aws,on-nexus-proxy,nexus-proxy,aeegerrit,on-nexus3,on-nexus4,.openet-dublin,10.65.224.59,.openet.com,docker.sock,localaddress,.localdomain,.localdomain.com,illinlic01,indlinsls,linvc04,bitbucket,gitlab,ldap,10.232.233.70,10.19.50.20,10.19.50.20,genproxy,10.17.88.18,10.17.88.22,10.232.217.1,10.232.217.2,10.20.40.100,10.19.214.200,distributionstg,artifactorystg,distribution,artifactory,.socket,168.63.129.16,169.254.169.254,169.254.169.253,169.254.169.123,127.254.254.254,teleproxy,traffic-manager.ambassador,"(hostname -s),(hostname -f),(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'|tr '\n' ',')(host -4 (hostname -f) 2>/dev/null | grep '\.' | grep -v "not found" | grep -v \":\" | awk '{print $NF}' | tr '\n' ',')localhost4,"$CUSTOM_NO_PROXY","$custom_no_proxy",10.0.0.0,172.16.0.0,192.168.0.0"
" | tee /etc/systemd/system/containerd.service.d/http-proxy.conf | tee /etc/systemd/system/crio.service.d/http-proxy.conf > /etc/systemd/system/docker.service.d/docker_proxy.conf
  end
  if test \( (is_docker) -eq "1" \)
    sudo systemctl daemon-reload >/dev/null 2>&1 || true
    echo "$argv0 - in WSL/docker, skipping systemctl restart. You have to do yourself:"
    echo "sudo systemctl restart docker.service containerd.service crio.service"
  else
    echo "$0 - restarting docker/containerd/crio services ..."
    sudo systemctl daemon-reload
    sudo systemctl restart docker.service containerd.service crio.service >/dev/null 2>&1 || true
  end
end

function docker_proxy_off
  echo "$funcname$argv:"
  sudo mkdir -p /etc/systemd/system/docker.service.d
  echo "\
[Service]
#Environment=http_proxy=http://genproxy.corp.amdocs.com:8080
#Environment=https_proxy=http://genproxy.corp.amdocs.com:8080
#Environment=no_proxy=localhost,127.0.0.1,127.0.1.1,.svc,.default,.local,.internal,.testing,fs.amdocs.com,.amdocs.com,.sock,.neo.corp.amdocs.aws,on-nexus-proxy,nexus-proxy,aeegerrit,on-nexus3,on-nexus4,.openet-dublin,10.65.224.59,.openet.com,docker.sock,localaddress,.localdomain,.localdomain.com,illinlic01,indlinsls,linvc04,bitbucket,gitlab,ldap,10.232.233.70,10.19.50.20,10.19.50.20,genproxy,10.17.88.18,10.17.88.22,10.232.217.1,10.232.217.2,10.20.40.100,10.19.214.200,distributionstg,artifactorystg,distribution,artifactory,.socket,168.63.129.16,169.254.169.254,169.254.169.253,169.254.169.123,127.254.254.254,teleproxy,traffic-manager.ambassador,"(hostname -s),(hostname -f),(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'|tr '\n' ',')(host -4 (hostname -f) 2>/dev/null | grep '\.' | grep -v "not found" | grep -v \":\" | awk '{print $NF}' | tr '\n' ',')localhost4,"$CUSTOM_NO_PROXY","$custom_no_proxy",10.0.0.0,172.16.0.0,192.168.0.0"
    " | sudo tee /etc/systemd/system/containerd.service.d/http-proxy.conf | sudo tee /etc/systemd/system/crio.service.d/http-proxy.conf > /etc/systemd/system/docker.service.d/docker_proxy.conf
  if [ \( (is_wsl) -eq "1" \) -o \( (is_docker) -eq "1" \) ]; then
    echo "$0 - in WSL/docker, skipping systemctl restart"
  else
    echo "$0 - restarting docker ..."
    sudo systemctl daemon-reload
    sudo systemctl restart docker.service containerd.service crio.service >/dev/null 2>&1 || true
  end
end

#########################
### debian (e.g. Ubuntu)#
#########################

function debian_machine_wide_proxy_on
  echo "$funcname$argv:"
  #As user (not root, not sudo)
  gsettings set org.gnome.system.proxy mode auto 2>/dev/null; or true # when there is no gnome (e.g. docker, ignore error)
  gsettings set org.gnome.system.proxy autoconfig-url 'http://wpad.corp.amdocs.com/wpad.dat' 2>/dev/null; or true # when there is no gnome (e.g. docker, ignore error)
  
  if test (is_wsl) -eq "1" -o (is_docker) -eq "1"
    echo "$0 - in WSL/docker, skipping nmcli"
  else
    set NMCLI_EXISTS (type nmcli 2>/dev/null; or true | grep -c " is "; or true)
    if test $NMCLI_EXISTS -gt "0"
      echo (status function; or true)(status current-command; or true)":amdocs search domain exists, removing it and network restart for 1st active interface (if you have more, do it manually)"
      set interfaceid (nmcli --fields uuid --colors no c show --active | tail -1 | tr -d " ")
      set INT1 $interfaceid"x"
      if test $INT1 != "x"
        sudo nmcli connection modify $interfaceid proxy.method "auto"; or true
        sudo nmcli connection modify $interfaceid proxy.pac-url "http://wpad.corp.amdocs.com/wpad.dat"; or true
        echo "check using: sudo nmcli connection show"
      end
    else
      echo "nmcli is missing. For best experience, please install it using sudo apt install network-manager"
    end
  end
end

function debian_machine_wide_proxy_off
  echo "$_function:$argv"
  #As user (not root, not sudo)
  gsettings set org.gnome.system.proxy autoconfig-url '' 2>/dev/null || true # when there is no gnome (e.g. docker, ignore error)
  gsettings set org.gnome.system.proxy mode none 2>/dev/null || true # when there is no gnome (e.g. docker, ignore error)

  if [ \( (is_wsl) -eq "1" \) -o \( (is_docker) -eq "1" \) ]
    echo "$_function:$argv - in WSL/docker, skipping nmcli"
  else
    set NMCLI_EXISTS (type nmcli > /dev/null ; and echo $status)
    if [ $NMCLI_EXISTS -gt "0" ]
      echo "$_function:$argv:amdocs search domain exists, removing it and network restart for 1st active interface (if you have more, do it manually)"
      set interfaceid (nmcli --fields uuid --colors no c show --active | tail -1 | tr -d " ")
      set INT1 "$interfaceid"x
      if [ "$INT1" != "x" ]
        sudo nmcli connection modify $interfaceid proxy.method "auto" || true
      end
    else
      echo "nmcli is missing. For best experience, please install it using sudo apt install network-manager"
    end
  end
end

function debian_snap_proxy_on
  echo (string join "" $argv[1] $argv[2])":"
  sudo mkdir -p /etc/systemd/system/snapd.service.d

  if [ \( (is_wsl) -eq "1" \) -o \( -f /etc/eaas.info \) ]
    echo "$argv[0] - in WSL"
    echo "\
[Service]
#Environment=http_proxy=http://wslproxy.corp.amdocs.com:8080
#Environment=https_proxy=http://wslproxy.corp.amdocs.com:8080
Environment=http_proxy=http://wslproxy.corp.amdocs.com:8080
Environment=https_proxy=http://wslproxy.corp.amdocs.com:8080
Environment=no_proxy=localhost,127.0.0.1,127.0.1.1,.svc,.default,.local,.internal,.testing,fs.amdocs.com,.amdocs.com,.sock,.neo.corp.amdocs.aws,on-nexus-proxy,nexus-proxy,aeegerrit,on-nexus3,on-nexus4,.openet-dublin,10.65.224.59,.openet.com,docker.sock,localaddress,.localdomain,.localdomain.com,illinlic01,indlinsls,linvc04,bitbucket,gitlab,ldap,10.232.233.70,10.19.50.20,10.19.50.20,genproxy,10.17.88.18,10.17.88.22,10.232.217.1,10.232.217.2,10.20.40.100,10.19.214.200,distributionstg,artifactorystg,distribution,artifactory,.socket,168.63.129.16,169.254.169.254,169.254.169.253,169.254.169.123,127.254.254.254,teleproxy,traffic-manager.ambassador,"(hostname -s),(hostname -f),(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'|tr '\n' ',')(host -4 (hostname -f) 2>/dev/null | grep '\.' | grep -v "not found" | grep -v \":\" | awk '{print $NF}' | tr '\n' ',')localhost4,"$CUSTOM_NO_PROXY","$custom_no_proxy",10.0.0.0,172.16.0.0,192.168.0.0"
" | sudo tee /etc/systemd/system/snapd.service.d/snap_proxy.conf >/dev/null
  else
    echo "$argv[0] - not in WSL"
    echo "\
    [Service]
Environment=http_proxy=http://genproxy.corp.amdocs.com:8080
Environment=https_proxy=http://genproxy.corp.amdocs.com:8080
Environment=no_proxy=localhost,127.0.0.1,127.0.1.1,.svc,.default,.local,.internal,.testing,fs.amdocs.com,.amdocs.com,.sock,.neo.corp.amdocs.aws,on-nexus-proxy,nexus-proxy,aeegerrit,on-nexus3,on-nexus4,.openet-dublin,10.65.224.59,.openet.com,docker.sock,localaddress,.localdomain,.localdomain.com,illinlic01,indlinsls,linvc04,bitbucket,gitlab,ldap,10.232.233.70,10.19.50.20,10.19.50.20,genproxy,10.17.88.18,10.17.88.22,10.232.217.1,10.232.217.2,10.20.40.100,10.19.214.200,distributionstg,artifactorystg,distribution,artifactory,.socket,168.63.129.16,169.254.169.254,169.254.169.253,169.254.169.123,127.254.254.254,teleproxy,traffic-manager.ambassador,"(hostname -s),(hostname -f),(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'|tr '\n' ',')(host -4 (hostname -f) 2>/dev/null | grep '\.' | grep -v "not found" | grep -v \":\" | awk '{print $NF}' | tr '\n' ',')localhost4,"$CUSTOM_NO_PROXY","$custom_no_proxy",10.0.0.0,172.16.0.0,192.168.0.0"
" | sudo tee /etc/systemd/system/snapd.service.d/snap_proxy.conf >/dev/null
  end
end

function debian_snap_proxy_off
  echo "$_function:$argv"
  sudo mkdir -p /etc/systemd/system/snapd.service.d
  echo "\
[Service]
#Environment=http_proxy=http://genproxy.corp.amdocs.com:8080
#Environment=https_proxy=http://genproxy.corp.amdocs.com:8080
#Environment=no_proxy=localhost,127.0.0.1,127.0.1.1,.svc,.default,.local,.internal,.testing,fs.amdocs.com,.amdocs.com,.sock,.neo.corp.amdocs.aws,on-nexus-proxy,nexus-proxy,aeegerrit,on-nexus3,on-nexus4,.openet-dublin,10.65.224.59,.openet.com,docker.sock,localaddress,.localdomain,.localdomain.com,illinlic01,indlinsls,linvc04,bitbucket,gitlab,ldap,10.232.233.70,10.19.50.20,10.19.50.20,genproxy,10.17.88.18,10.17.88.22,10.232.217.1,10.232.217.2,10.20.40.100,10.19.214.200,distributionstg,artifactorystg,distribution,artifactory,.socket,168.63.129.16,169.254.169.254,169.254.169.253,169.254.169.123,127.254.254.254,teleproxy,traffic-manager.ambassador,"(hostname -s),(hostname -f),(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'|tr '\n' ',')(host -4 (hostname -f) 2>/dev/null | grep '\.' | grep -v "not found" | grep -v \":\" | awk '{print $NF}' | tr '\n' ',')localhost4,"$CUSTOM_NO_PROXY","$custom_no_proxy",10.0.0.0,172.16.0.0,192.168.0.0"
" | sudo tee /etc/systemd/system/snapd.service.d/snap_proxy.conf >/dev/null
  if [ (is_wsl) = "1" ] || [ (is_docker) = "1" ]
    echo "$argv[1] - in WSL/docker, skipping systemctl restart"
  else
    echo "$argv[1] - restarting docker ..."
    sudo systemctl daemon-reload
    sudo systemctl restart snapd.service >/dev/null 2>&1 || true
  end
end

function debian_software_manager_gui_on
  echo "$_function:$argv:debian/Ubuntu software manager (GUI) - proxy on"
  echo ' 
#https://manpages.debian.org/testing/apt/apt-transport-http.1.en.html
Acquire::http {
  Proxy::ilcedtoapt.corp.amdocs.com DIRECT;
  #Proxy "http://genproxy.corp.amdocs.com:8080";
  Proxy-Auto-Detect "/usr/local/bin/apt-autoproxy.sh";
  Dl-Limit "99000";
  Pipeline-Depth "99";

  ## if probelmatic proxy, uncomment/change/enable
  #No-Cache "true";
  #No-Store "true";
  #Max-Age "3660"
  #Pipeline-Depth "0";
  #SendAccept "false";
}

Acquire::https {
  Proxy::ilcedtoapt.corp.amdocs.com DIRECT;
  #Proxy "http://genproxy.corp.amdocs.com:8080";
  Proxy-Auto-Detect "/usr/local/bin/apt-autoproxy.sh";
  Dl-Limit "99000";
  Pipeline-Depth "99";

  ## if probelmatic proxy, uncomment/change/enable
  #No-Cache "true";
  #No-Store "true";
  #Max-Age "3660"
  #Pipeline-Depth "0";
  #SendAccept "false";
}

## To debug possible issues:
#Debug::Acquire::http "yes";
#Debug::Acquire::https "yes";

Acquire::BrokenProxy   "true";
' | sudo tee /etc/apt/apt.conf.d/23proxy >/dev/null
  
  echo "Creating also /usr/local/bin/apt-autoproxy.sh"
  echo '  
#!/usr/bin/env sh
  # In the future use pacparser with http://wpad.corp.amdocs.com/wpad.dat
  # if looking for an amdocs website, return DIRECT
  COUNT=$(echo $@ | grep -c '\.amdocs\.com' || true )
  if [ $COUNT -gt 0 ]; then
    #echo -n "direct://"
    echo -n "DIRECT"
    exit 0
  fi

  # If not FQDN, return DIRECT
  COUNT=$(echo $@ | grep -c \'\.\' || true )
  if [ $COUNT -eq 0 ]; then
    echo -n "DIRECT"
    exit 0
  fi

  # If it\'s an IP address, return DIRECT
  COUNT=$(echo -n $@ | tr -d \'[0-9\.]\' | wc -c )
  if [ $COUNT -eq 0 ]; then
    echo -n "DIRECT"
    exit 0
  fi
' | sudo tee /usr/local/bin/apt-autoproxy.sh >/dev/null

  echo 'export PROXY_URL=$(proxy_get_url)' | sudo tee -a /usr/local/bin/apt-autoproxy.sh >/dev/null

echo '
  PROXY_HOST=$(echo $PROXY_URL | cut -d"/" -f3 | cut -d":" -f1 )
  PROXY_PORT=$(echo $PROXY_URL | cut -d":" -f3 | cut -d"/" -f1 )
  if nc -4 -w2 -z $PROXY_HOST $PROXY_PORT >/dev/null 2>/dev/null ; then
    #ping test cannot be used by the _apt user
    echo -n "${PROXY_URL}"
    exit 0
  else
    #echo -n "direct://"
    echo -n "DIRECT"
    exit 0
  fi
  echo -n "DIRECT"
  # When we exit without printing any echo, the default defined proxy is used.
  exit 0
' | sudo tee -a /usr/local/bin/apt-autoproxy.sh >/dev/null
  sudo chmod +x /usr/local/bin/apt-autoproxy.sh
  end

