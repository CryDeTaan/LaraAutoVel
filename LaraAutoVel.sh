#!/usr/bin/env bash

# Let's get the user input and assign to variables
# There has probably gone more work into this than what is required.
# But as everything, this was another opportunity to learn some new things :)

# I use a lot of comments as this is how I learn what each thing does. 
# The more I started to do it the more I noticed that I retain the information.
# At the end of the day I create this for me, if other people use it, then great, 
# but ultimately I do it the way that work for me and provides me with a way to learn something new.

# TODO I am not sure if I should be handling the errors myself. I still need to decide what is going to work best for me. 
# But at the time of writing this comment, I feel that I am going to end up handling errors myself.
#set -e 

__version__="0.1"
__author__="CryDeTaan"

# Set some variables that well help with formatting and colours in the output during execution. 

# Set some colours and formatting using ANSI escape codes (a.k.a ANSI escape sequences), a standard for
# in-band signaling to control the cursor location, color, and other options on video text terminals. 
# Certain sequences of bytes, most starting with Esc and '[', are embedded into the text, 
# which the terminal looks for and interprets as commands, not as character codes.
# https://en.wikipedia.org/wiki/ANSI_escape_code

# Colours
RED="\033[31m"
BLACK="\033[30m"
GREEN="\033[32m"
YELLOW="\033[33m"
NC="\033[0m"    # No colour

# Formating
UL="\033[4m"    # Underline
BLD="\033[1m"    # Bold
CL="\033[K"     # Clear line
CLF="\033[0m"   # Clear formatting
SPACE="    "    # Spacing

CHECK_MARK="${GREEN}\xE2\x9C\x94${CLF}"
BALLOT_X="${RED}\xE2\x9C\x98${CLF}"
EXCLA_MARK="${YELLOW}\xE2\x9D\x97${CLF}"

hide_cursor="\033[?25l"
unhide_cursor="\033[?25h"
format_loading="\r\033[K\t%-20s%s"
format_checked="\r\033[K\t%-20s${CHECK_MARK}\n"
format_failed="\r\033[K\t%-20s${BALLOT_X}\n"


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

    # Initially I wanted the ability to choose whether or not to run the web server as a normal user or as root.
    # I have done a lot of work to make sure that the web server can run as normal user. So I decided to remove the ability to choose.
    # 1. No, it's not because it's more secure, it was just to much effort to make it possible for very little benefit.
    # 2. It's more secure ;p

    # Setting some local variables for this function.
    local runas_user password

    # Read the inputs from the user. Should a user be created that will be used to manage the web server.
    #printf " 1. ${UL}It's recommended to create a new ${BLD}non${CLF}${UL}-root user (Default)${CLF}\n"
    printf " 1. ${UL}Let's create a ${BLD}non${CLF}${UL}-root user${CLF}\n"
    #read -p "${SPACE}(Y)es: Create new user. (N)o: Run as root: "  runas_user

    # If the input was to create a user, this is where it will happen. Else, let's print that the web server will be managed as root.
    #if [[ "$runas_user" =~ ^(y|Y)[a-z]{0,2}$ ]] || [[ ! $runas_user  ]] ; then
        
        printf "${SPACE}Please enter the following details:\n"
        read -p "${SPACE}Username: " username
        read -sp "${SPACE}Password: " password
        echo

        # Add the user, change the password and add the user to the wheel group.
        adduser $username
        echo $username:$password | chpasswd
        usermod -aG wheel $username

    #elif [[ "$runas_user" =~ ^(n|N)[a-z]{0,1}$ ]]; then
    #    printf "${RED}${SPACE}Will run as root!${NC}\n"
    #else
    #    banner
    #    printf "\e[1A"
    #    printf "${RED}${SPACE}Invalid option, please try again${NC}\n"
    #    runas
    #fi

}


function set_locales() {

# As many people know Locale errors are always a problem, this is actually an ssh issue as your terminal client 
# when opening an ssh session wants to set the local to something that may not be on a remote system.
# Adding LANG=en_US.utf-8 and LC_ALL=en_US.utf-8 to /etc/environment. This should sort it out. 

echo LANG=en_US.utf-8 >> /etc/environment && echo LC_ALL=en_US.utf-8 >> /etc/environment
export LANG=en_US.utf-8 && export LC_ALL=en_US.utf-8

}


function check_ssh() {

    # I still want to do something here. Not sure what, but this needs to do something.

    local password_auth

    password_auth=$(sshd -T | grep -i passwordauthentication | awk {'print $2'})

    if [[ $password_auth = 'no' ]];then
        sed -i.bak "s/PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config
        service sshd restart &>/dev/null
    fi

}


function load(){

    # This function will basically print 3 dots is a sequence . .. ... 
    # This will make the current process look like it is loading or busy.
    # For me this was actually a challenging problem to solve which I did not expect.

    # The way I achieve this is by passing a PID and the package name to this function. 
    # Then using the PID in a while loop to print the package name and the 3 dot sequence until the PID is no longer detected.

    local pid pid_name

    declare -a dots=(" " "." ".." "...")

    pid=$1
    pid_name=$2

    printf "${hide_cursor}"

    # Once the PID is no longer detected, the loop will end and based on the result of the process the parent funtion will pass
    # the exit code to display the correct result based on that exit code. 

    while [[ $(ps a | awk '{print $1}' | grep $pid) ]]
    do

        for dot in "${dots[@]}";
        do
            printf "$format_loading" $pid_name $dot
            sleep 0.2
        done

    done

    printf "${unhide_cursor}"

}

function display_result() {

    # Receiving a exit code from the last process, could be installation of a component, or configuration, etc.
    # Using this exit code to either display a checkmark for successfull or a ballot-x if the process failed.

    local pid pid_name

    pid_result=$1
    pid_name=$2

    sleep 0.3

    if ! [[ $pid_result -eq 0 ]]
    then    

        # TODO: Add logging

        printf "$format_failed" $pid_name
        return 1

    fi

    printf "$format_checked" $pid_name
    return 0
}


function setting_repos() {

    # This is realy the first action required before any packages are installed. 
    
    # Three things happen:
    # 1. Adding repo keys, first time yum runs you need to verify the pgp keys that is used to sign the packages.
    # 2. Adding the Extra Packages for Enterprise Linux (EPEL) and Inline with Upstream Stable (IUS) community project repos
    # 3. yum update, Note that the load() function will not handle the printing or the error handling for yum update.

    local repo_pid

    printf "\n 2. ${UL}Setting Repos${CLF}\n"
   

    declare -a repos=(  "epel-release=epel-release"
                        "ius=https://centos7.iuscommunity.org/ius-release.rpm"
                     )

    # 1. CentOS Repo keys
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

    # 2.1 Adding epel and ius repos
    
    for repo in "${repos[@]}"
    do

        set -- `echo $repo | tr '=' ' '`
        repo_name=$1
        repo=$2

        yum install -y -q $repo  &>/dev/null 2>$repo_name.log &
        repo_pid=$!

        load $repo_pid $repo_name
        wait $repo_pid

        display_result $? $repo_name

    done

    # 2.2 Adding repo keys. 
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
    rpm --import /etc/pki/rpm-gpg/IUS-COMMUNITY-GPG-KEY

    # 3. yum update
    yum update -y -q &>/dev/null 2>update.log &
    yum_pid=$!

    load $yum_pid yum-update
    wait $yum_pid

    display_result $? yum-update

}


function install_components() {

    # Simple function that loops through a array that specifies all the packages that needs to be installed.
    # The package is installed in the background, but passing the PID and the package name to the load() function.
    # The stdout from yum will be suppressed although the stderr will be sent to a log file. 

    printf "\n 3. ${UL}Installing Components${CLF}\n"

    # All the packages in an array.
    local components
    declare -a components=( "zsh" "vim" "git" "curl" "unzip" "certbot" "php72u"
                       "php72u-cli" "php72u-fpm-nginx" "php72u-json"
                       "php72u-mbstring" "php72u-xml" "firewalld" 
                     )
    
    # Loop that will install each package.
    for component in "${components[@]}"
    do
        yum install -y -q $component &>/dev/null 2>$component.log  &    
        component_pid=$!

        load $component_pid $component
        wait $component_pid

        display_result $? $component

    done

    # Seeing that composer is also a component, I think it's just obvious to call it from here.
    install_composer 
}


function install_composer() {

    # Like most things in this scrip, this one is also a bit hack-ish  

    # I'll be relying on a long sleep and use the PID from this sleep to detect when all the steps from this function completed. 
    # I am sure this is probably not the best way to do this, but ¯\_(ツ)_/¯

    # These variables are set to the context of this function only. 
    local expected_signature actual_signature kpid 

    sleep 6000 &
    kpid=$!
    load $kpid composer &
    load_pid=$!

    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"

    expected_signature=$(curl -s https://composer.github.io/installer.sig)
    actual_signature="$(php -r "echo hash_file('SHA384', 'composer-setup.php');")"

    if [[ $expected_signature != $actual_signature ]]
    then
        # TODO: Add logging 

        # Kill the PID which will end the load() loop
        disown $kpid
        kill $kpid
        
        wait $load_pid
        # Print the failed ballot-x mart 
        display_result 1 composer

        return 1
    fi

    php composer-setup.php --quiet
    mv composer.phar /usr/local/bin/composer
    rm composer-setup.php

    export PATH="$HOME/.config/composer/vendor/bin:$PATH"

    sleep 2

    if ! [[ -x "$(command -v composer)" ]]; then
        # TODO: Add logging 

        # Kill the PID which will end the load() loop
        disown $kpid
        kill $kpid

        wait $load_pid
        # Print the failed ballot-x mart 
        display_result 1 composer

        return 1
    fi

    # If all is well we can kill the PID from the long sleep and print the green checkmark
    disown $kpid
    kill $kpid
    
    wait $load_pid

    display_result 0 composer

}



function config_components() {

    # TODO: Add commenting 

    # This function will call all the other configuration functions.
        
    printf "\n 4. ${UL}Configuring Component's defaults${CLF}\n"

    # Keeping with the them of using the load() function.
    # Let's loop over each of the functions while the component is being configured. 

    local components

    declare -a components=("php=config_php" "nginx=conf_nginx" "starting_services=starting_services")


    # Loop that will install each package.
    for component in "${components[@]}"
    do

        set -- `echo $component | tr '=' ' '`
	    component_name=$1
	    component=$2

        sleep 6000 &
        kpid=$!
        load $kpid $component_name &
        load_pid=$!
        
        $component
        config_result=$?

        sleep 2

        disown $kpid
        kill $kpid

        wait $load_pid
        display_result $config_result $component_name

    done


}


function config_php() {

    # PHP-FPM is required to allow the Webserver, in this case Nginx, to execute PHP code. Furthermore, PHP-FPM can handle multiple pools of child processes via a local TCP socket.
    # However, Nginx expects a Unix domain socket, which we can map to a path on the filesystem. :) 
    
    # Sounds fancy and all, but all that is really needed are these two lines.

    local sed_result

    # The first comments out this listen = 127.0.0.1:9000
    sed -i.bak '/^listen = 127.*9000$/s/^/;/' /etc/php-fpm.d/www.conf
    grep '^;listen = 127.*9000$' /etc/php-fpm.d/www.conf &>/dev/null
    declare -i sed_result=$?

    # Next uncomment this ;listen = /run/php-fpm/www.sock
    sed -i.bak '/^;listen = .*www.sock$/s/^;//' /etc/php-fpm.d/www.conf
    grep '^listen = .*www.sock$' /etc/php-fpm.d/www.conf &>/dev/null
    sed_result=$sed_result+$?

    # Next uncomment this ;listen = /run/php-fpm/www.sock
    sed -i.bak '/^;listen.acl_users\s*=\s*nginx$/s/^;//' /etc/php-fpm.d/www.conf
    grep '^listen.acl_users\s*=\s*nginx$' /etc/php-fpm.d/www.conf &>/dev/null
    sed_result=$sed_result+$?

    if [[ $sed_result -gt 0 ]]; then
        # TODO: Some logging required
        # TODO: Add the ability to restore the back up of the config file.

        return 1
    fi

    return 0

}

function conf_nginx() {

    local sed_result

    sed -i.bak '/server\s127.*9000;$/s//#&/' /etc/nginx/conf.d/php-fpm.conf
    grep '^\s*#server 127.*9000;$' /etc/nginx/conf.d/php-fpm.conf &>/dev/null
    declare -i sed_result=$?

    sed -i.bak '/^\s*#server\s.*www.sock;$/s/#//' /etc/nginx/conf.d/php-fpm.conf
    grep '^\s*server.*www.sock;$' /etc/nginx/conf.d/php-fpm.conf &>/dev/null
    sed_result=$sed_result+$?
    
    sed -i.bak 'N;s/\(^\s*\)\(include.*\/conf\.d\/.*conf;\)/\1\2\n\1include \/etc\/nginx\/sites\.conf\.d\/\*\.conf;/' /etc/nginx/nginx.conf
    grep 'include.*sites.*conf;' /etc/nginx/nginx.conf &>/dev/null
    sed_result=$sed_result+$?

   # TODO: Add commenting 
   #sed -i.bak '/^\s*location \/ {$/,+1s/^/#/' /etc/nginx/nginx.conf
    sed -i 'N;s/\(^\s*\)\(location\s*\/\s*{\)\n\(\s*\)\(}\).*$/\1#\2\n\3#\4/' /etc/nginx/nginx.conf
    grep -Pazo '^#\s*location \/ {$\R#\s*}$' /etc/nginx/nginx.conf &>/dev/null
    sed_result=$sed_result+$?

    if [[ $sed_result -gt 0 ]]; then
        # TODO: Some logging required
        # TODO: Add the ability to restore the back up of the config file.
        return 1
    fi

    return 0
}

function starting_services() {

    local execution_result

    systemctl enable nginx &>/dev/null 2>starting_services.log
    declare -i execution_result=$?

    systemctl start nginx &>/dev/null 2>>starting_services.log
    execution_result=$execution_result+$?

    systemctl enable php-fpm &>/dev/null 2>>starting_services.log
    execution_result=$execution_result+$?

    systemctl start php-fpm &>/dev/null 2>>starting_services.log
    execution_result=$execution_result+$?

     if [[ $execution_result -gt 0 ]]; then
        # TODO: Some logging required
        # TODO: Add the ability to restore the back up of the config file.
        return 1
    fi

    return 0
}

function applying_security() {

    # TODO: Add commenting 

    # This function will call all the other configuration functions.
        
    printf "\n 5. ${UL}Applying Security${CLF}\n"

    # Keeping with the them of using the load() function.
    # Let's loop over each of the functions while the component is being onfigured. 

    local components

    declare -a components=("SELinux=config_selinux" "lets_encrypt=config_ssl" "firewalld=config_firewalld" )


    # Loop that will install each package.
    for component in "${components[@]}"
    do

        set -- `echo $component | tr '=' ' '`
	    component_name=$1
	    component=$2

        sleep 6000 &
        kpid=$!
        load $kpid $component_name &
        load_pid=$!
        
        $component
        config_result=$?

        sleep 2

        disown $kpid
        kill $kpid

        wait $load_pid
        display_result $config_result $component_name

    done


}

function config_selinux() {

    # SELinux
    
    local execution_result

    curl -s -O https://raw.githubusercontent.com/CryDeTaan/LaraAutoVel/master/SELiux/php-fpm.te &>/dev/null 2>SELinux.log
    declare -i execution_result=$?

    checkmodule -M -m -o php-fpm.mod php-fpm.te &>/dev/null 2>>SELinux.log
    execution_result=$execution_result+$?

    semodule_package -o php-fpm.pp -m php-fpm.mod &>/dev/null 2>>SELinux.log
    execution_result=$execution_result+$?

    semodule -i php-fpm.pp &>/dev/null 2>>SELinux.log
    execution_result=$execution_result+$?

    semodule -l | grep php-fpm &>/dev/null 2>>SELinux.log
    execution_result=$execution_result+$?

    rm -f php-fpm.* &>/dev/null 2>>SELinux.log
    execution_result=$execution_result+$?
    
     if [[ $execution_result -gt 0 ]]; then
        # TODO: Some logging required
        # TODO: Add the ability to restore the back up of the config file.
        return 1
    fi

    return 0

}

function config_ssl() {

    local execution_result

    openssl dhparam -out /etc/ssl/certs/dhparam.pem 4096 &>/dev/null 2>openssl_dhparam.log
    declare -i execution_result=$?

    mkdir -p /var/www/letsencrypt/.well-known/acme-challenge &>/dev/null 2>ssl.log
    execution_result=$execution_result+$?

    echo "30 2 * * * certbot renew --post-hook 'nginx -s reload' >> /var/log/letsencrypt/le-renew.log" >> cronfile 
    execution_result=$execution_result+$?

    crontab cronfile &>/dev/null 2>>ssl.log
    execution_result=$execution_result+$?

    rm -f cronfile &>/dev/null 2>>ssl.log
    execution_result=$execution_result+$?

    crontab -l | grep -P '^\d{1,2}.*certbot\srenew.*log$' &>/dev/null 2>>ssl.log
    execution_result=$execution_result+$?

    nginx -s reload
    execution_result=$execution_result+$?

     if [[ $execution_result -gt 0 ]]; then
        # TODO: Some logging required
        # TODO: Add the ability to restore the back up of the config file.
        return 1
    fi

    return 0

}

function config_firewalld() {

    local execution_result

    systemctl enable firewalld &>/dev/null 2>firewalld.log
    declare -i execution_result=$?

    systemctl start firewalld &>/dev/null 2>>firewalld.log
    execution_result=$execution_result+$?

    firewall-cmd --permanent --zone=public --add-service=http &>/dev/null 2>>firewalld.log
    execution_result=$execution_result+$?

    firewall-cmd --permanent --zone=public --add-service=https &>/dev/null 2>>firewalld.log
    execution_result=$execution_result+$?

    firewall-cmd --reload &>/dev/null 2>>firewalld.log
    execution_result=$execution_result+$?

     if [[ $execution_result -gt 0 ]]; then
        # TODO: Some logging required
        # TODO: Add the ability to restore the back up of the config file.
        return 1
    fi

    return 0

}

function framework_components() {

    # This function will be used to configure and setup the LaraAutoVel framework components. 
    # This includes cloning the repository, setting the template config files, default configs, and 
    # the let's encrypt config files.

    printf "\n 6. ${UL}Setting up the LaraAutoVel Framework${CLF}\n"

    # Keeping with the them of using the load() function.
    # Let's loop over each of the functions while the component is being configured. 

    local components

    declare -a components=(
                            "git=git_clone" 
                            "symlinks=setting_symlinks" 
                            "permissions=setting_permissions" 
                            "nginx=setting_nginx"
                          )

    # Loop that will install each package.
    for component in "${components[@]}"
    do

        set -- `echo $component | tr '=' ' '`
	    component_name=$1
	    component=$2

        sleep 6000 &
        kpid=$!
        load $kpid $component_name &
        load_pid=$!
        
        $component
        config_result=$?

        sleep 2

        disown $kpid
        kill $kpid

        wait $load_pid
        display_result $config_result $component_name

    done


}



function git_clone() {

    # TODO: Add commenting

    local execution_result

    # Cloning the LaraAutoVel repo. 
    git clone -q https://github.com/CryDeTaan/LaraAutoVel.git /home/$username/LaraAutoVel/ 2>>git.log
    declare -i execution_result=$?


    chown -R $username:$username /home/$username/LaraAutoVel
    execution_result=$execution_result+$?

     if [[ $execution_result -gt 0 ]]; then
        # TODO: Some logging required
        # TODO: Add the ability to restore the back up of the config file.
        return 1
    fi

    return 0

}

function setting_symlinks() {

    # This function will create all the folders and the requird symlinks, and permissions for the LaraAutoVel Framework.

    local execution_result

    mkdir -p /home/$username/www &>/dev/null 2>symlinks.log
    declare -i execution_result=$?

    ln -s /var/www/html /home/$username/www/sites &>/dev/null 2>>symlinks.log
    execution_result=$execution_result+$?

    ln -s /etc/nginx/sites.conf.d /home/$username/www/sites.conf.d &>/dev/null 2>>symlinks.log
    execution_result=$execution_result+$?

     if [[ $execution_result -gt 0 ]]; then
        # TODO: Some logging required
        # TODO: Add the ability to restore the back up of the config file.
        return 1
    fi

    return 0
}


function setting_permissions() {
    
    local execution_result

    setfacl -m u:$username:rwx /etc/nginx/conf.d &>/dev/null 2>>permissions.log
    declare -i execution_result=$?

    setfacl -m u:$username:rwx /var/www/html &>/dev/null 2>>permissions.log
    execution_result=$execution_result+$?

    setfacl -Rdm u:php-fpm:rwx /var/www/html &>/dev/null 2>permissions.log
    execution_result=$execution_result+$?

     if [[ $execution_result -gt 0 ]]; then
        # TODO: Some logging required
        # TODO: Add the ability to restore the back up of the config file.
        return 1
    fi

    return 0
}


function setting_nginx() {

    # This function will create all the folders and the requird symlinks, and permissions for the LaraAutoVel Framework.

    local execution_result

    cp /home/$username/LaraAutoVel/nginx/*.conf /etc/nginx/default.d/ &>/dev/null 2>nginx_config.log
    declare -i execution_result=$?

    cp /home/$username/LaraAutoVel/ssl/*.conf /etc/nginx/default.d/ &>/dev/null 2>>nginx_config.log
    execution_result=$execution_result+$?

     if [[ $execution_result -gt 0 ]]; then
        # TODO: Some logging required
        # TODO: Add the ability to restore the back up of the config file.
        return 1
    fi

    return 0
}

function starting_and_testing() {

    # This function will be used to configure and setup the LaraAutoVel framework components. 
    # This includes cloning the repository, setting the template config files, default configs, and 
    # the let's encrypt config files.

    printf "\n 7. ${UL}Starting and testing services${CLF}\n"

    # Keeping with the them of using the load() function.
    # Let's loop over each of the functions while the component is being configured. 

    local components

    declare -a components=(
                            "test_site=test_site" 
                            "restarting_services=restarting_services"
                            "testing=testing"
                            "cleanup=testing_cleanup"
                          )

    # Loop that will install each package.
    for component in "${components[@]}"
    do

        set -- `echo $component | tr '=' ' '`
	    component_name=$1
	    component=$2

        sleep 6000 &
        kpid=$!
        load $kpid $component_name &
        load_pid=$!
        
        $component
        config_result=$?

        sleep 2

        disown $kpid
        kill $kpid

        wait $load_pid
        display_result $config_result $component_name

    done


}

function test_site() {

    # This function will create all the folders and the requird symlinks, and permissions for the LaraAutoVel Framework.
    
    local execution_result

    mkdir /home/$username/www/sites/test &>/dev/null 2>test_site.log
    declare -i execution_result=$?

    echo '<?php phpinfo();' > /home/$username/www/sites/test/info.php 2>>test_site.log
    execution_result=$execution_result+$?

    sed -e 's/443.*;$/80;/'  -e 's/${fqdn}/127.0.0.1/' -e 's/${appName}\/public/test/' -e '/ssl_certificate/d' /home/$username/LaraAutoVel/nginx/conf.d.example > /home/$username/www/conf.d/test.conf 2>>test_site.log
    execution_result=$execution_result+$?

    mv /etc/nginx/default.d/ssl-redirect.conf /etc/nginx/default.d/ssl-redirect.conf.tmp &>/dev/null 2>>test_site.log
    execution_result=$execution_result+$?

     if [[ $execution_result -gt 0 ]]; then
        # TODO: Some logging required
        # TODO: Add the ability to restore the back up of the config file.
        return 1
    fi

    return 0
}

function starting_services() {

    local execution_result

    systemctl restart nginx &>/dev/null 2>>starting_services.log
    declare -i execution_result=$?

    systemctl restart php-fpm &>/dev/null 2>>starting_services.log
    execution_result=$execution_result+$?

     if [[ $execution_result -gt 0 ]]; then
        # TODO: Some logging required
        # TODO: Add the ability to restore the back up of the config file.
        return 1
    fi

    return 0
}


function testing() {

    # This function will create all the folders and the requird symlinks, and permissions for the LaraAutoVel Framework.
    
    local execution_result

    curl -s http://127.0.0.1/info.php | grep -Po "PHP Version (\d.){2}\d" >testing_services.log 2>&1
    declare -i execution_result=$?

    php -v | grep -Po "PHP (\d.){2}\d\s\(cli\)" >>testing_services.log 2>&1
    execution_result=$execution_result+$?

     if [[ $execution_result -gt 0 ]]; then
        # TODO: Some logging required
        # TODO: Add the ability to restore the back up of the config file.
        return 1
    fi

    return 0
}

function testing_cleanup() {

    # This function will create all the folders and the requird symlinks, and permissions for the LaraAutoVel Framework.
    
    local execution_result

    rm -rf /home/$username/www/sites/test >testing_cleanup.log 2>&1
    declare -i execution_result=$?

    rm -f /home/$username/www/conf.d/test.conf >>testing_cleanup.log 2>&1
    execution_result=$execution_result+$?

    mv /etc/nginx/default.d/ssl-redirect.conf.tmp /etc/nginx/default.d/ssl-redirect.conf >>testing_cleanup.log 2>&1
    execution_result=$execution_result+$?

     if [[ $execution_result -gt 0 ]]; then
        # TODO: Some logging required
        # TODO: Add the ability to restore the back up of the config file.
        return 1
    fi

    return 0
}

function set_firewalld() {

 echo 'sd'
}



function web_stuff() {
    su -c "bash -c '$(curl -s https://raw)'" - $username
}

clear
banner
set_locales
runas
setting_repos
install_components
config_components
applying_security
framework_components
starting_and_testing
#echo Done
