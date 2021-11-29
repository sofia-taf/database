# database
# This readme file describes the process of installing tools necessary to recreate the backend database
# for sofia-tsaf
# This readme first describes how to install using MySQL then how to install the database and finally how to run scripts
# follow instructions here and for more information: https://dev.mysql.com/doc/refman/8.0/en/windows-install-archive.html
# https://dev.mysql.com/doc/refman/8.0/en/windows-create-option-file.html
# The PostGres version expects that the user has already installed and thus only the db is supplied
# Note: this was tested on postgres using linux not windows
# Cygwin is used as the shell scripting tool in this database package to install follow:
1. Create install directory usually C:\cygwin-installer
2. Download Cygwin installer https://cygwin.com/install.html
3. cd /cygdrive/c/Users/Nicole/cygwin-installer/
4. run installer file ./setup-x86_64.exe 

# setup chere 
open cygwin
chere -i -t mintty -s bash

# MySQL Install instructions
All the methods below involve downloading the package checking the signature(except github method), unpacking and installing.  That is pretty much it.
I don't like to use the installer since it includes too many extra things. 
# prerequisites: https://dev.mysql.com/doc/refman/8.0/en/source-installation-prerequisites.html
1. cmake downloaded here: http://www.cmake.org.
2. Boost C++ https://www.boost.org/
3. ncurses library https://invisible-island.net/ncurses/announce.html
4. gunzip if using tar compiled package, winzip if using zip file download
5. if using git revision control system then need bixon 2.1 or higher https://www.gnu.org/software/bison/
https://dev.mysql.com/downloads/mysql/
# Method 1. Windows only download an installer package that is tooled to install called: MySQL Installer
1. download MySQL Installer package from here: https://dev.mysql.com/downloads/installer/ (click archive to get previous version)
2. open cygwin shell and check signature of download:
md5sum.exe mysql-8.0.26-winx64.zip
MD5: 9b7af5c91139659b10b84b1ca357d08f mysql-installer-community-8.0.26.1.msi
3. update config file if you wish located here: C:\Windows  add file my.cnf and include the items below
4. Run installer as admin

# Method 2: Install MySQL using noinstall zip Windows
1. download community version 8.26 of mysql noinstall zip (Zip ARchive) for windows from here: https://dev.mysql.com/downloads/installer/ (click archive to get previous version)
2. open cygwin and check signature:
md5sum mysql-8.0.26-winx64.zip
db32c0669cc809abb465bb56e76c77a1 *mysql-8.0.26-winx64.zip 

3. Update config file to at least the following.  Linux usual location is etc/my.cnf windows is usually navigate to where you downloaded package
5. Run install usr/bin/mysql_secure_installation
6. ./mysqld --defaults-file=C:\\Windows\\my.cnf --initialize
7.  ./mysql_secure_installation.exe
8. start server  ./mysqld.exe --console
# Method 3: Install MySQL for Linux https://dev.mysql.com/doc/refman/8.0/en/installing-source-distribution.html
make sure you do not have a pre-installed version that may not be compatible with this version.
1. download community version 8.26 of mysql tar file from here: https://dev.mysql.com/downloads/installer/ (click archive to get previous version)
2. open cygwin and check signature:
md5sum mysql-8.0.26-el7-x86_64.tar.gz
MD5: ad605821afb685ab4bb3b3c4c66b3d86 mysql-8.0.26-el7-x86_64.tar.gz
3. Install dependencies: Note for red hat 8 el8 to include /lib64/kibtinfo.so.5 yum install ncurses-compat-libs
4. cd usr/local/mysql move downloaded file here and unpack:
5. gunzip mysql-8.0.26-el7-x86_64.tar.gz
6. follow commands from oracle -mysql page: https://dev.mysql.com/doc/refman/8.0/en/binary-installation.html
$> groupadd mysql
$> useradd -r -g mysql -s /bin/false mysql
$> cd /usr/local
$> tar xvf /path/to/mysql-VERSION-OS.tar.xz
$> ln -s full-path-to-mysql-VERSION-OS mysql
$> cd mysql
$> mkdir mysql-files
$> chown mysql:mysql mysql-files
$> chmod 750 mysql-files
$> bin/mysqld --initialize --user=mysql
$> bin/mysql_ssl_rsa_setup
$> bin/mysqld_safe --user=mysql &
7. Add config file see below: 
8. start mysql server: systemctl start mysqld

# Method 4: Install from github site following: above method 3 except skip step 1 -5 https://dev.mysql.com/doc/refman/8.0/en/installing-development-tree.html#installing-development-tree-git
replace steps 1-5 with
git clone https://github.com/mysql/mysql-server.git
git checkout 8.0
git pull

# my.cnf file and for windows add to C:Windows and for linux add to /etc/my.cnf existing
# replace pasword with your valid password from the MySQL install and D:\\ with valid path to mysql data
[client]
# The following password is sent to all standard MySQL clients
password=
port=3306
socket=D:\\tmp\\sql.sock

[mysqld]
secure-file-priv = ""
port=3306
socket=D:\\mysql\\tmp\\sql.sock
datadir=D:\\mysql\\data
basedir=D:\\mysql
log-bin=D:\\mysql\\log\\mysql-bin.log
log-error=D:\\mysql\\log\\mysql-error.log
bind-address="127.0.0.1"
tmpdir=D:\\tmp
innodb_data_file_path = ibdata1:10M:autoextend
max_heap_table_size=214748364800
tmp_table_size=214748364800

# setup config editor for ease of scripting
if added mysql as user:
mysql_config_editor set --login-path=mysql_rw --host=localhost --user=mysql --password

mysql_config_editor set --login-path=mysql_rw --host=localhost --user=root --password
 
cat<<"EOF" | ./mysql --login-path=mysql_rw -vvv
 SET GLOBAL local_infile=1;
 SHOW GLOBAL VARIABLES LIKE 'local_infile';
EOF

# install most recent database using the following
mysql.exe --login-path=mysql_rw create schema tafp;
mysql.exe --login-path=mysql_rw tafp < tafp_mysqldump_2021*.sql

# create dump file if you had made changes that should be kept
mysqldump --login-path=mysql_rw tafp > D:/mysql/tafp_mysqldump_$(date +%Y%m%d).sql 


# custom stored procedure
to compare status and trends data you can create the same pivoted table using mysql stored procedure: 
parameters are area code and monitoring (if included in status and trends monitoring report data)
parameters are required but can accept NULL
data is aggregated by area-stock-year as is status and trends data
This data does contain qualifiers which are eliminated with the pivot data

call tafp.sproc_get_captures(31,NULL,"C://tmp")