#!/usr/bin/env bash

# Let's get the user input and assign to variables

set -e 


__version__="0.1"
__author__="CryDeTaan"

RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
CL='\033[2K'
SPACE='    '

function banner() {
    clear
    printf "
    --------------------------------------------------------------------
    |${RED}    _                         _        _____                 _   ${NC} |
    |${RED}   | |             /\        | |      |  __ \               | |  ${NC} |
    |${RED}   | |     __ _   /  \  _   _| |_ ___ | |__) |__ ___   _____| |  ${NC} |
    |${RED}   | |    / _\` | / /\ \| | | | __/ _ \|  _  // _\` \ \ / / _ \ |  ${NC} |
    |${RED}   | |___| (_| |/ ____ \ |_| | || (_) | | \ \ (_| |\ V /  __/ |  ${NC} |
    |${RED}   |______\__,_/_/    \_\__,_|\__\___/|_|  \_\__,_| \_/ \___|_|  ${NC} |
    |                                           ${GREEN}v%s - @%s    ${NC}  | 
    --------------------------------------------------------------------\n 
    A few questions are required.\n\n" "$__version__" "$__author__"
}

function runas(){

    local runas_user password

    echo -e ' 1. Its recommened to specify non-root user (Default)' 
    read -p '    (y)es, specify user or (n)o, ran as root: '  runas_user

    if [[ "$runas_user" =~ ^(y|Y)[a-z]{0,2}$ ]] || [[ ! $runas_user  ]] ; then
        
        echo '    Please enter the following details:'
        read -p '    Username: ' username
        read -sp '    Password: ' password
        echo

        #adduser $username
        #echo $username:$password | chpasswd
        #usermod -aG wheel $username
    elif [[ "$runas_user" =~ ^(n|N)[a-z]{0,1}$ ]]; then
        echo -e ${RED}"    Will run as root!"${NC}
    else
        echo -e ${CL}
        banner
        echo -e ${RED}"    Please try again"${NC}
        runas
    fi


}



function check_ssh() {

    local password_auth

    password_auth=$(sshd -T | grep -i passwordauthentication | awk {'print $2'})

    if [[ $password_auth = 'no' ]];then
        sed -i.bak "s/PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config
        service sshd restart &>/dev/null
    fi

}

function install_components() {

    yum install -y epel-release https://centos7.iuscommunity.org/ius-release.rpm &>dev/null

    yum update -y &>/dev/null

    yum install -y \
        zsh \
        vim \
        git \
        curl \
        certbo \
        php72u \
        php72u-cli \
        php72u-fpm-nginx \
        php72u-json \
        php72u-mbstring \
        php72u-xml &>/dev/null
}

function install_composer() {

    local expected_signature actual_signature result

    expected_signature=$(curl https://composer.github.io/installer.sig)
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    actual_signature="$(php -r "echo hash_file('SHA384', 'composer-setup.php');")"

    if [[ $expected_signature != $actual_signature ]]
    then
        echo Oops
        exit 1
    fi
   php composer-setup.php --quiet
   mv composer.phar /usr/local/bin/composer
   rm composer-setup.php

   export PATH="$HOME/.config/composer/vendor/bin:$PATH"


}

function install_dotfiles() {
 echo 'sd'
}

function confi_php() {

 echo 'sd'
}

function conf_nginx() {

 echo 'sd'
}

function conf_laravel() {

 echo 'sd'
}

function user_permissions() {

 echo 'sd'
}

function set_selinux() {

 echo 'sd'
}

function set_firewalld() {

 echo 'sd'
}



function web_stuff() {
    su -c "bash -c '$(curl -s https://raw)'" - $username
}

clear
banner
runas
install_components
echo Done




