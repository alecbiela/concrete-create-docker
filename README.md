# concrete-create-docker
Initialize the framework for a Concrete CMS dev site in a few minutes using Docker Compose.

## Purpose
The purpose of this project is to speed up the time it takes to create a local development environment for a Concrete CMS website. It is **not** intended to be used to deploy websites into a production environment.

## Prerequisites
It is highly recommended that you have [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed on your development machine, as this includes support for Docker Compose and allows you to interact with your containers, images, and builds for important information without deep knowledge of the command line.  
  
In addition, you will also need a way to generate a self-signed SSL certificate. The instructions below contain a command for generating a certificate using OpenSSL on Linux/WSL.

## Instructions
1. Pull this repository and enter it (replace *my-project-name* with your own)  
```
git clone https://github.com/alecbiela/concrete-create-docker.git my-project-name
cd my-project-name
```  
  
2. If you don't already have one, create an SSL certificate for `localhost` using OpenSSL or a similar service (if you have already done this for a previous site, you can re-use the files it created). For example:    
```
openssl req -x509 -new -nodes -newkey rsa:2048 -keyout mycert.key -sha256 -days 18250 -out mycert.crt -subj /CN='localhost ca'
```  
  
3. Move your cert and key files to the `ssl/` directory.  
**Important:** the cert and key file must be named **mycert.crt** and **mycert.key** respectively.  
  
4. Make a copy (or rename) the **.env.example** file to **.env**. Open this file in a text editor and edit the parameters as necessary. See below for variable information:  
* `SITE_HANDLE` - The name of the Docker Container, which will also be used to prefix your volume and image names.
* `CONCRETE_VERSION` - The version of Concrete CMS to be used. Valid options are any version listed on [the Concrete5 Packagist Repository](https://packagist.org/packages/concrete5/concrete5). The latest release version is recommended.
* `PHP_VERSION` - The PHP Version to use. Only the major and minor version numbers are needed, e.g. `7.4` or `8.1`.
* `MYSQL_VERSION` - The version of MySQL to use. **Note:** See "Using MySQL" below. Recommended values are `9.1.0`, `8.4.3`, `lts`, and `8.0.40`.
* `MARIADB_VERSION` - The version of MariaDB to use. Recommended values are `11.5.2`, `11.4.3`, `11.2.5`, `11.1.6`, `10.11.9`, `10.6.19`, and `10.5.26`.
* `TIME_ZONE` - The TZ database identifier for your time zone. See [the Wikipedia article](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List) for a list of possible values (located in the "TZ identifier" column of the table).
* `PHPMYADMIN_PORT` - When the container is running, you will visit "localhost:xxxx" in your browser to access PHPMyAdmin, where `xxxx` is this value.
* `DB_USERNAME` - The User Account name which Concrete CMS will use to access the database.
* `DB_PASSWORD` - The password for the above account.
* `DB_NAME` - The name of the database Concrete CMS will store its data in.
* `DB_ROOT_PW` - The password for accessing the database with a username of `root`. This may be useful if you need to change some database settings that require root access, but in general you should use the separate account you specified above.

5. If you are running MacOS or Linux, consider switching your file location from a volume to a bind-based setup. See "Using Bind-Mapped Files" below.  
  
6. Inside a terminal/command prompt window in your project's folder, start the services with:  
`docker compose up -d --build`  
  
The first-time start will take a couple minutes as it pulls the base data and installs everything, but subsequent starts will be much faster. You'll know it's finished when you receive a bunch of "Started" messages in the terminal window, you receive the prompt to enter another command, and you can see your container appear in the "Containers" tab of Docker Desktop.  
  
7. Visit `localhost` in a web browser. You may need to "Accept the security risk" because of using a self-signed SSL certificate. You should see the Concrete CMS install screen.  
  
8. Install Concrete CMS as you normally would. Make sure to include the same information from your `.env` file, including the database credentials and Time Zone.  
  
**For the database host, simply enter `db:3306`**. Docker will resolve it to your database service.  

### Using MySQL
By default, MariaDB is used since MySQL does not publish ARM-based images, meaning it won't run on computers that use this architecture (like Apple-Silicon Macs). If you really need to, you can edit `compose.yaml` to install the database using MySQL. Under the `db` section  (line 21), change the image to pull from MySQL, like so:  
```
  db:
    #image: mariadb:${MARIADB_VERSION} <--- Put a # in front of this line
    image: mysql:${MYSQL_VERSION} <--- Remove the # from the front of this line
```  
  
### Using Bind-Mapped Files
In its default configuration, this Docker Compose script creates volumes on the Docker Virtual Machine to store the files for the webserver and database. This is because on Windows, mounting a folder from an NTFS drive with your files results in a serious performance hit (~10x slowdown). However, using WSL on Windows enables you to easily navigate to the volumes on the VM itself; they'll be stored in something like:  
`\\wsl.localhost\docker-desktop\mnt\docker-desktop-disk\data\docker\volumes`  
  
In a Mac or Linux environment, it isn't as easy to connect an IDE to the Docker VM. You may in this instance want to switch to *bind-mapping* for your project files, in which you bind a local folder on your machine to the docker VM, enabling you to more easily edit your code. To do this, open `compose.yaml` and edit line `15`:  
  
`vol_web:/var/www/html`  
  
Change `vol_web` to a path relative to the current folder. For example, if I wanted my data to be stored in a folder called "web_data", I'd change it to:  
  
`./web_data:/var/www/html`  
  
You can also delete the entire line under volumes for "vol_web:" (line 42) of the compose.yaml file. This prevents it from needlessly linking to/mounting a volume which is never used. After running  
  
`docker compose up -d --build`  
  
you should see a new folder created using the name you specified with all of the Concrete CMS installation files.
  
## Explanation
What exactly is happening here? Essentially, what this script is doing is installing a LAMP-stack using Docker Compose with two separate services; one for the web server and one for the DB. While the database image requires no modification, the webserver is built off a Dockerfile that starts with the Apache-loaded PHP as a base. It installs PHP Composer as well as the OS packages and PHP extensions needed to run Concrete CMS. It sets up SSL on localhost using the provided cert, and lastly pulls down the specified version of Concrete CMS using Composer.  
  
### Multiple Development Servers
If you're working on multiple sites at once, you may follow the installation procedure multiple times as long as the folders you clone the repository to are different (you can even skip the cert generation and just copy the cert files over from one project's "ssl" folder to the next). Switching the dev site is as simple as opening Docker Desktop, stopping the container of the site that's currrently running, and starting the container for the other site you'd like to view/work on. You can also do this in the command line by heading to the project's folder and running `docker compose down`, then navigating to the other site and running `docker compose up -d`.  
  
It's also possible to run a reverse proxy such as nginx in Docker and link multiple site containers to it, but that's not supported by this project.

## Final Notes
This project is licensed under the MIT license. Feel free to use it in accordance with that.  
  
I'm still an extreme novice in Docker, so if there are any large issues or better ways to go about some of these things please feel free to shoot me a PM or open an Issue/Pull Request.



