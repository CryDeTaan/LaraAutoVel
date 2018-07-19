#!/usr/bin/env bash

# Let's get the user input and assign to variables
# There has probably gone more work into this than what is required.
# But as everything, this was another opportunity to learn some new things :)

# I use a lot of comments as this is how I learn what each thing does. 
# The more I started to do it the more I noticed that I retain the information.
# At the end of the day I create this for me, if other people use it, then great, 
# but ultimately I do it the way that work for me and provides me with a way to learn something new.

set -e 


__version__="0.1"
__author__="CryDeTaan"

#
# Set some variables that well help with formatting and colours in the output during execution. 
#
# Set some colours using ANSI escape codes (a.k.a ANSI escape sequences), a standard for
# in-band signaling to control the cursor location, color, and other options on video text terminals. 
# Certain sequences of bytes, most starting with Esc and '[', are embedded into the text, 
# which the terminal looks for and interprets as commands, not as character codes.
# https://en.wikipedia.org/wiki/ANSI_escape_code

# Colours
RED="\e[31m"
BLACK="\e[30m"
GREEN="\e[32m"
NC="\e[0m"    # No colour

# Formating
UL="\e[4m"    # Underline
BLD="\e[1m"    # Bold
CL="\e[K"     # Clear line
CLF="\e[0m"   # Clear formatting
SPACE="    "    # Spacing

CHECK_MARK="${GREEN}\xE2\x9C\x94${CLF}"

hide_cursor="\033[?25l"
unhide_cursor="\033[?25h"
format_loading="\r\033[K\t%-20s%s"
format_checked="\r\033[K\t%-20s${CHECK_MARK}\n"


function banner() {
    clear
    printf "
    --------------------------------------------------------------------
    |${RED}      _                                   _    __      __  _     ${NC} |
    |${RED}     | |                       /\        | |   \ \    / / | |    ${NC} |
    |${RED}     | |     __ _ _ __ __ _   /  \  _   _| |_ __\ \  / /__| |    ${NC} |
    |${RED}     | |    / _\` | \'__/ _\` | / /\ \| | | | __/ _ \ \/ / _ \ |    ${NC} |
    |${RED}     | |___| (_| | | | (_| |/ ____ \ |_| | || (_) \  /  __/ |    ${NC} |
    |${RED}     |______\__,_|_|  \__,_/_/    \_\__,_|\__\___/ \/ \___|_|    ${NC} |
    |                                           ${GREEN}v%s - @%s    ${NC}  | 
    --------------------------------------------------------------------\n 
    A few questions are required.\n\n" "$__version__" "$__author__"
}

function runas(){

    local runas_user password
    printf " 1. ${UL}It's recommended to create a new ${BLD}non${CLF}${UL}-root user (Default)${CLF}\n"
    read -p "${SPACE}(Y)es: Create new user. (N)o: Run as root: "  runas_user

    if [[ "$runas_user" =~ ^(y|Y)[a-z]{0,2}$ ]] || [[ ! $runas_user  ]] ; then
        
        printf "${SPACE}Please enter the following details:\n"
        read -p "${SPACE}Username: " username
        read -sp "${SPACE}Password: " password
        echo

        #adduser $username
        #echo $username:$password | chpasswd
        #usermod -aG wheel $username
    elif [[ "$runas_user" =~ ^(n|N)[a-z]{0,1}$ ]]; then
        printf "${RED}${SPACE}Will run as root!${NC}\n"
    else
        banner
        printf "\e[1A"
        printf "${RED}${SPACE}Invalid option, please try again${NC}\n"
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

function load(){



    declare -a dots=(" " "." ".." "...")

    pid=$1
    pid_name=$2

    printf "${hide_cursor}"
    while [[ $(ps a | awk '{print $1}' | grep $pid) ]]
    do

        for dot in "${dots[@]}";
        do
            printf "$format_loading" $pid_name $dot
            sleep 0.2
        done
    done
    printf "$format_checked" $pid_name

    printf "${unhide_cursor}"

}

function setting_repos() {


    printf " 2. ${UL}Setting Repos${CLF}\n"
   
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

    yum install -y -q epel-release >/dev/null 2>epel.log &
    #sleep 2 &
    load $! epel-release
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

    yum install -y -q https://centos7.iuscommunity.org/ius-release.rpm  >/dev/null 2>ius.log &
    #sleep 3 &
    load $! ius
    rpm --import /etc/pki/rpm-gpg/IUS-COMMUNITY-GPG-KEY

    yum update -y -q >/dev/null 2>update.log &
    #sleep 3 &
    load $! yum-update

}


function install_components() {

    printf " 3. ${UL}Installing Components${CLF}\n"

    declare -a components=( "zsh" "vim" "git" "curl" "certbot" "php72u"
                       "php72u-cli" "php72u-fpm-nginx" "php72u-json"
                       "php72u-mbstring" "php72u-xml"
                     )
    
    #declare -a components=( "zsh" "vim")

    for component in "${components[@]}"
    do
        yum install -y -q $component >/dev/null 2>$component.log  &
        #sleep 1 &
        load $! $component
    done
}

function install_composer() {


    local expected_signature actual_signature result

    sleep 6000 &
    kpid=$!

    load $kpid composer &


    expected_signature=$(curl -s https://composer.github.io/installer.sig)
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

    sleep 2

    disown $kpid
    kill $kpid
    sleep 1
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
setting_repos
install_components
install_composer
#echo Done
