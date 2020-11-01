#!/bin/bash

#############################################################################
########                        DISCLAIMER                            #######
#############################################################################
###
# This script is property of FELIPE W N PEREIRA and cannot be distributed or
# used by anyone other than FELIPE W N PEREIRA.

###
# This script make automatic download and instalation of:
# Zabbix Server (3.4)
# Zabbix Agent (3.4)
# MariaDB (Latest Version)
# PHP (Latest Version)

###
# AUTHOR = FELIPE WAGNER DO NASCIMENTO PEREIRA
# DATE = 19/03/2018




#############################################################################
########                         Variables                            #######
#############################################################################
###
# Variables that need to be edited for automatic deploy:
PHP_TIMEZONE='America/Sao_Paulo'
MARIADB_PASSWD='mPassword'
ZABBIX_DB_USER='zUser'
ZABBIX_DB_PASSWD='zPassword'
ZABBIX_DB_NAME='zdb'
ZBBIX_REPO='https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm'
###
# Usualy theese default variables works:
CENTOS_PHP_INI='/etc/php.ini'
ZABBIX_SERVER_CONF='/etc/zabbix/zabbix_server.conf'
ZABBIX_AGENT_CONF='/etc/zabbix/zabbix_agentd.conf'
SELINUX_CONF='/etc/selinux/config'

#############################################################################
########                        Pre-Conditions                        #######
#############################################################################
###
# This script need some things installed and working to procceed:
# yum
# ping
# Internet
# sed
# zcat
# epel
# Permissive or Disabled SELinux
# setenforce
# getenforce


# Check if yum is availiable and executable
#1
if [ ! -x /usr/bin/yum ]; then
	#2
	echo -e "\n\n\n\n";
    echo "Yum not availiable.";
	echo "Closing...";
    exit;
fi

# Simple check on DNS resolution and internet connection
#3
if [ -x /usr/bin/ping ]; then
	#4
	if ! ping -q -c5 google.com > /dev/null; then
		#5
		echo -e "\n\n\n\n";
		echo "Seems like there is a problem with your internet!";
		echo "DNS or ICMP is not working/available!";
		echo "Closing...";
		exit;
	fi
#6
else
	echo -e "\n\n\n\n";
	echo "Ping is not availiable.";
	echo "Cannot check your internet connection.";
	echo "Closing...";
	exit;
fi

# Check if sed is available and executable
if [ ! -x /usr/bin/sed ]; then
	echo -e "\n\n\n\n";
	echo "sed is not availiable.";
	echo "Trying to install sed.";
	yum install sed -y;
	if [ ! -x /usr/bin/sed ]; then
		echo -e "\n\n\n\n";
		echo "Couldn't install sed.";
		echo "Closing...";
		exit;
	fi
fi

# Check if zcat is available and executable
if [ ! -x /usr/bin/zcat ]; then
	echo -e "\n\n\n\n";
	echo "zcat is not availiable.";
	echo "Trying to install zcat.";
	yum install gzip -y;
	if [ ! -x /usr/bin/zcat ]; then
		echo -e "\n\n\n\n";
		echo "Couldn't install zcat.";
		echo "Closing...";
		exit;
	fi
fi

# Disable SELinux

# Now
# Test if setenforce is executable
if [ -x /usr/sbin/setenforce ]; then
	setenforce 0;
else
	echo -e "\n\n\n\n";
	echo "setenforce is not availiable.";
	echo "[WARNING] This might keep your zabbix from working!";	
fi

# Test if getenforce is executable
if [ -x /usr/sbin/getenforce ]; then
	# Check if SELinux is Disabled or Permissive
	case "$(getenforce)" in
		[Dd]isabled*)
			;;
		[Pp]ermissive*)
			;;
		*)
			echo -e "\n\n\n\n";
			echo "Could not disable SELinux.";
			echo "[WARNING] This might keep your zabbix from working!";
			;;
	esac
else
	echo -e "\n\n\n\n";
	echo "getenforce is not availiable.";
	echo "[WARNING] This might keep your zabbix from working!";
fi

# Forever
sed -ie "s@.*SELINUX=.*@@g" $SELINUX_CONF;
echo "######CHANGES-BY-IZABIX#####" >> $SELINUX_CONF;
echo "SELINUX=permissive" >> $SELINUX_CONF;
if [ ! -e $SELINUX_CONF ]; then
	echo -e "\n\n\n\n";
	echo "Couldn't disable SELinux in $SELINUX_CONF";
	echo "[WARNING] This might keep your zabbix from working!";
fi

# Install epel-release repository
if ! yum install epel-release -y; then 
	echo "[WARNING] Epel release couldn't be installed."; 
fi



#############################################################################
########                   Temporary File Creation                    #######
#############################################################################
###
# Create MariaDB secure installation script
echo "UPDATE mysql.user SET Password=PASSWORD('$MARIADB_PASSWD') WHERE User='root';" > /tmp/mariadb_secure_installation.sql
echo "DELETE FROM mysql.user WHERE User='';" >> /tmp/mariadb_secure_installation.sql
echo "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" >> /tmp/mariadb_secure_installation.sql
echo "DROP DATABASE IF EXISTS test;" >> /tmp/mariadb_secure_installation.sql
echo "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';" >> /tmp/mariadb_secure_installation.sql
echo "FLUSH PRIVILEGES;" >> /tmp/mariadb_secure_installation.sql
chmod 0600 /tmp/mariadb_secure_installation.sql
###
# Create Zabbix database installation script
echo "create database $ZABBIX_DB_NAME character set utf8 collate utf8_bin;" > /tmp/izabbix.sql
echo "grant all privileges on $ZABBIX_DB_NAME.* to '$ZABBIX_DB_USER'@'localhost' identified by '$ZABBIX_DB_PASSWD';" >> /tmp/izabbix.sql
echo "flush privileges;" >> /tmp/izabbix.sql
chmod 0600 /tmp/izabbix.sql

#############################################################################
########                           Program                            #######
#############################################################################


#############################################################################
########                           Step 1                             #######
#############################################################################
###
# Install Apache Web Server and PHP
yum install httpd php php-mysql php-ldap php-bcmath php-mbstring php-gd php-xml php-mcrypt -y

# Tune PHP interpreter to run Zabbix Server
echo "######CHANGES-BY-IZABIX#####" >> $CENTOS_PHP_INI

# Set max_execution_time to 300
sed -ie "s@.*max_execution_time =.*@@g" $CENTOS_PHP_INI
echo "max_execution_time = 300" >> $CENTOS_PHP_INI

# Set memory_limit to 128M
sed -ie "s@.*memory_limit =.*@@g" $CENTOS_PHP_INI
echo "memory_limit = 128M" >> $CENTOS_PHP_INI

# Set always_populate_raw_post_data to -1
sed -ie "s@.*always_populate_raw_post_data =.*@@g" $CENTOS_PHP_INI
echo "always_populate_raw_post_data = -1" >> $CENTOS_PHP_INI

# set session.auto_start to 0
sed -ie "s@.*session.auto_start =.*@@g" $CENTOS_PHP_INI
echo "session.auto_start = 0" >> $CENTOS_PHP_INI

# Set mbstring.func_overload to 0
sed -ie "s@.*mbstring.func_overload =.*@@g" $CENTOS_PHP_INI
echo "mbstring.func_overload = 0" >> $CENTOS_PHP_INI

# Set date.timezone to $PHP_TIMEZONE variable
sed -ie "s@.*date.timezone =.*@@g" $CENTOS_PHP_INI
echo "date.timezone = $PHP_TIMEZONE" >> $CENTOS_PHP_INI

# Restart apache service
systemctl restart httpd.service

#############################################################################
########                           Step 2                             #######
#############################################################################
###
# Install MariaDB Database and Library
yum install mariadb-server mariadb-client mariadb-devel -y

# Make sure mariadb is runnning
systemctl restart mariadb.service

# Run mariadb security post installation script
mysql -sfu root < /tmp/mariadb_secure_installation.sql
rm /tmp/mariadb_secure_installation.sql

# Create Zabbix database
mysql -sfu root -p$MARIADB_PASSWD < /tmp/izabbix.sql
rm /tmp/izabbix.sql

#############################################################################
########                           Step 3                             #######
#############################################################################
###
# Install Zabbix 3.4.2 repository
rpm -ivh $ZABBIX_REPO

# Install Zabbix Server
yum install zabbix-server-mysql zabbix-web-mysql -y

# Install Zabbix Agent
yum install zabbix-agent -y

# Restart apache
systemctl restart httpd.service

#############################################################################
########                           Step 4                             #######
#############################################################################
### Configure Zabbix Server and Agent

# Create initial data
echo "Creating Zabbix DB initial data..."
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -u $ZABBIX_DB_USER -p$ZABBIX_DB_PASSWD $ZABBIX_DB_NAME
echo "Done..."

# Configure Zabbix server database connection
echo "######CHANGES-BY-IZABIX#####" >> $ZABBIX_SERVER_CONF

# Set DBHost to localhost
sed -ie 's@.*DBHost=.*@@g' $ZABBIX_SERVER_CONF
echo "DBHost=localhost" >> $ZABBIX_SERVER_CONF

# Set DBName to $ZABBIX_DB_NAME
sed -ie 's@.*DBName=.*@@g' $ZABBIX_SERVER_CONF
echo "DBName=$ZABBIX_DB_NAME" >> $ZABBIX_SERVER_CONF

# Set DBUser to $ZABBIX_DB_USER
sed -ie 's@.*DBUser=.*@@g' $ZABBIX_SERVER_CONF
echo "DBUser=$ZABBIX_DB_USER" >> $ZABBIX_SERVER_CONF

# Set DBPassword to $ZABBIX_DB_PASSWD
sed -ie 's@.*DBPassword=.*@@g' $ZABBIX_SERVER_CONF
echo "DBPassword=$ZABBIX_DB_PASSWD" >> $ZABBIX_SERVER_CONF

# Restart Zabbix server service
systemctl restart zabbix-server.service

# Configure Zabbix agent
echo "######CHANGES-BY-IZABIX#####" >> $ZABBIX_AGENT_CONF

# Set Server to localhost
sed -ie 's@.*Server=.*@@g' $ZABBIX_AGENT_CONF
echo "Server=localhost" >> $ZABBIX_AGENT_CONF

# Set ListenPort to 10050
sed -ie 's@.*ListenPort=.*@@g' $ZABBIX_AGENT_CONF
echo 'ListenPort=10050' >> $ZABBIX_AGENT_CONF

# Restart Zabbix agent service
systemctl restart zabbix-agent.service

# Enable Zabbix agent service
systemctl enable zabbix-agent.service

# Enable Zabbix server service
systemctl enable zabbix-server.service

# Enable apache service
systemctl enable httpd.service

# Enable mariadb service
systemctl enable mariadb.service

if [ -x /usr/bin/firewall-cmd ]; then
	# Add firewall exception
	firewall-cmd --permanent --zone=public --add-service=http
	# Reload Firewall
	firewall-cmd --reload
else
	echo -e "\n\n\n\n";
    echo "firewall-cmd not availiable.";
	echo "[WARNING] This might keep your zabbix from working!";
fi

# Clear any output garbage
# clear;
