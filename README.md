# LaraAutoVel

### For scaffolding a CentOS server, ready to deploy your Laravel Applications.

---

```
* ---------------------------------------------------------------- *
|      _                                   _    __      __  _      |
|     | |                       /\        | |   \ \    / / | |     |
|     | |     __ _ _ __ __ _   /  \  _   _| |_ __\ \  / /__| |     |
|     | |    / _` | '__/ _` | / /\ \| | | | __/ _ \ \/ / _ \ |     |
|     | |___| (_| | | | (_| |/ ____ \ |_| | || (_) \  /  __/ |     |
|     |______\__,_|_|  \__,_/_/    \_\__,_|\__\___/ \/ \___|_|     |
|                                           v1.1 - @CryDeTaan      |
* ---------------------------------------------------------------- *
```
---

LaraAutoVel installs and configures all the packages and components required to run a basic Laravel Web Application on a 
CentOS server.

I started this project because each time I have to spin up a new web app I have to go through the pain of figuring out 
how I did it, and what worked and what didn't work for me. I do not spin up web apps often, but when I do, 
I want to do it quickly.

At first, I did it manually, but also consistently ([Consistent CentOS Framework for running Laravel web apps](https://medium.com/@crydetaan/consistent-centos-framework-for-running-laravel-web-apps-1eac1221f68e)), 
but I wanted to automate it further and not copy and paste my commands
from a note I created.

LaraAutoVel will sort out the following for you:
- php
- nginx web server configs
- MariaDB/MySQL
- supporting components such as composer
- testing
- security (let's encrypt certs, HTTP headers, SELinux, and correct permissions for normal user)

**Warning - Do not run this on a server that you are already using as a web server!**
See [Support](#support) for more information.

## Quick Start
Run the following command, this will add an alias called LaraAutoVel.

    bash <(curl -fsSL https://raw.githubusercontent.com/crydetaan/LaraAutoVel/master/LaraAutoVel.sh)

Once the installation is finished, please see the "[Adding a new Laravel Web App](#adding-a-new-laravel-web-app)" 
section below on how to add a new Laravel web app.

**NOTE:** The lets-encrypt install can take a very very long time, just be patient, it should finish.

## What you get

LaraAutoVel will install and configure the following components:

```
 1. Set Repos
	epel-release        ✔
	ius                 ✔
	yum-update          ✔

 2. Install Packages and Components
	zsh                 ✔
	vim                 ✔
	git                 ✔
	curl                ✔
	unzip               ✔
	certbot             ✔
	php72u              ✔
	php72u-cli          ✔
	php72u-fpm-nginx    ✔
	php72u-json         ✔
	php72u-mbstring     ✔
	php72u-xml          ✔
	mariadb-server      ✔
	firewalld           ✔
	composer            ✔

 3. Configure Components
	php                 ✔
	nginx               ✔
	mariadb             ✔
	start-services      ✔

 4. Apply Security
	SELinux             ✔
	lets-encrypt        ✔
	firewalld           ✔

 5. Setup LaraAutoVel Framework
	git                 ✔
	symlinks            ✔
	permissions         ✔
	nginx               ✔

 6. Test LaraAutoVel
	test-site           ✔
	restart-services    ✔
	testing             ✔
	cleanup             ✔
```

As can be seen by the list above, LaraAutoVel takes care of everything that is needed to run a Laravel Web Application.

This setup is repeatable and will consistently give you a workable server with security and ease of use.

Here is what it looks like in action.

[![asciicast](https://asciinema.org/a/IfKDREcX6hiKTrhETUlJMTJA4.png)](https://asciinema.org/a/IfKDREcX6hiKTrhETUlJMTJA4?speed=2&theme=tango&autoplay=1)


## Adding a new Laravel Web App.

From this point on you only have to follow these steps for ever new site you want to host on the server that you 
provisioned with LaraAutoVel.

But before that, and this is **important**, you need to set your fully qualified domain name (FQDN) where you host 
your DNS for the site that you are about to provision. I am not going to go into more details about FQDN, DNS, 
and hostnames at this time, but if you need help, please feel free to contact me and I'll gladly assist you.

So before we get started, ssh to the the server using the new username you created during the installation. 
Once you are logged in follow these steps.

There are two folders of importance. These are created automatically in ~/www and the correct permissions are set.
These directories are symlinks to locations in the file system used by nginx to load and present the Laravel web apps.

- **sites** -> /var/www/html - This is where all the Laravel web apps will live. 
- **sites.conf.d** -> /etc/nginx/sites.conf.d - This is the location for the config of each site. 


---

**1\. A few variables will be used. Set them by replacing the brackets `< >`.** 

```
appName=<appName>
fqdn=<fqdn>
```
These variables will be used when creating the folder structure and setting the nginx config.

**2\. Create the directory for the Laravel App**

```sh
mkdir ~/www/sites/$appName
cd ~/www/sites/$appName
```

You will notice that this www directory is in the root of your user's home directory. It is a symlink to `/var/www/html/`

The permissions to this directory is set during the LaraAutoVel installation process.

**3\. Git clone project**

As an example, I’ll be deploying the base Laravel App. But this is where you will pull in your repository. 

```sh
git clone https://github.com/laravel/laravel.git .
```

**4\. Copy and update the nginx config.**

The example (conf.d.example) in the LaraAutoVel framework directory (~/LaraAutoVel/nginx/) will be used to 
create the necessary config for nginx to publish the new app to the public.

```sh
sed -e "s/\${fqdn}/$fqdn/" -e "s/\${appName}/$appName/" ~/LaraAutoVel/nginx/conf.d.example > ~/www/sites.conf.d/$appName.conf
```

**5\. Composer Install** 

From the root location of the Laravel Web App, you can run composer install, this will, as you know, pull in any
dependencies as well as the Laravel Framework.

```sh
composer install --optimize-autoloader
```

**6\. Setup Laravel environment**
As you probably already know, Laravel requires a .env file. This file needs to be populated for any Laravel Web App to 
function. This is only an example and does not make use of all the properties; for example 
DB connections or SMTP settings. Also remember to set your .env file according to your requirements.

```sh
cp .env.example .env
```

Then we need a new application key. The application key is a random string that is used for sessions and encryption
data within the application among other things. 

From the Laravel App root directory run the following:

```sh
php artisan key:generate
```

**7\. Let’s Encrypt Certificate**

Let’s add a Let’s Encrypt for our new Laravel App.

```sh
sudo certbot certonly --webroot -w /var/www/letsencrypt -d $fqdn
```

**NOTE**: The first time the certbot is run a few questions will be asked.

Issues:
This is the part that will require an actual hostname.domain pointing to your server IP Address. 
If you are not planning on using a DNS name, you can skip this step, but you will also have to edit the `.conf` 
file located at `~/www/sites.conf.d`

Comment out the two lines which start with `ssl_certificate`

**8\. Reload**

Lastly, lets reload Nginx config for the changes to take affect. 
 
```sh
sudo nginx -s reload
```

**9\. Done**

At this point the default Laravel Web App which we cloned in step one will run successfully.

If your web application requires a database, or another component such as node or yarn, you'll have to install them yourself. 

In  future releases I'll add support for this. 


## Support 

**Warning - Do not run this on a server that you are already using as a web server**

This ideally works on a newly provisioned server. I expect major issues if you run this on a server that already has 
components such as php and nginx configured.

This script is really the first thing you'll run on a newly built CentOS server.

I used Digital Ocean's CentOS image during testing. So I know it works on their image. Digital Ocean's droplets 
(yes, that's what is called) start from $5 a month.

*If you do not have a Digital Ocean Account yet, I'll appreciate your support: 
[Referral link](https://m.do.co/c/61005e039b63)*


## TODO

Some of the feature I still want to add.

- Logging
- ~~MySQL/MariaDB support~~
- Automated adding of Laravel Web Apps
- Aesthetic/Visual changes
- Commenting in the code

## License

See the [LICENSE](https://github.com/CryDeTaan/LaraAutoVel/blob/master/LICENSE) file for license rights and limitations (MIT).
