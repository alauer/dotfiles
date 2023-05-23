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
if test (grep 'docker\|lxc' /proc/1/cgroup | wc -l) -gt 1
    echo "1"
else
    echo "0"
end
end