## USE LIKE THIS:
# source <(curl -ksS https://gitlab.corp.amdocs.com/ansible-roles/image-template/raw/master/files/profile_proxy.sh)
# proxy install  # for install in /etc/profile.d/
# proxy on       # to run on|off|install
########
### CORE FUNCTIONALITY:
function proxy
switch "$1"
case 'a|auto'
    proxyauto
case 'af|auto_full|install|reinstall'
    proxy_install_in_profile_auto && proxyauto && proxy_os_configs_auto && proxyauto && echo "check using: proxy status"
case 'c|proxy_os_configs_auto'
    proxy_os_configs_auto
case 'on|ON|On'
    proxyon $2
case 'off|OFF|Off'
    proxyoff
case 's|status'
    proxystatus
case 'install_in_profile'
    proxy_install_in_profile
case 'force_on|full|on_force'
    proxyon && proxy_os_configs_on && proxy_install_in_profile_on && proxystatus
case 'help'
    proxyhelp
case '*'
    proxyon $1
end
end