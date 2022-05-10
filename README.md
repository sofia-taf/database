## Database Readme
###### This readme file describes the process of installing tools necessary to recreate the backend database
###### used to summarize Tier1, Tier2 and Tier3 data for sofia
###### This readme first describes how to install using MySQL, then how to install the database and finally how to run scripts
######  follow instructions here and for more information: https://dev.mysql.com/doc/refman/8.0/en/windows-install-archive.html
######  https://dev.mysql.com/doc/refman/8.0/en/windows-create-option-file.html


##### MySQL Install instructions
 All the methods below involve downloading the package checking the signature(except github method), unpacking and installing.  That is pretty much it.
 Prerequisites: https://dev.mysql.com/doc/refman/8.0/en/source-installation-prerequisites.html
> 1. cmake downloaded here: http://www.cmake.org.
> 2. Boost C++ https://www.boost.org/
> 3. ncurses library https://invisible-island.net/ncurses/announce.html
> 4. gunzip if using tar compiled package, winzip if using zip file download
> 5. if using git revision control system then need bixon 2.1 or higher https://www.gnu.org/software/bison/
> https://dev.mysql.com/downloads/mysql/
###### Method 1. Windows only -download installer package that is tooled to install MySQL Server
```
###### Cygwin is used as the shell scripting tool in this database package to install follow:
1. Create install directory usually C:\cygwin-installer
2. Download Cygwin installer https://cygwin.com/install.html to above directory
3. cd /cygdrive/c/Users/Nicole/cygwin-installer/
4. run installer file ./setup-x86_64.exe 

###### setup chere 
```

open cygwin as administrator
chere -i -t mintty -s bash
```
1. Download MySQL Installer package from here: https://dev.mysql.com/downloads/installer/ (click archive to get previous version)
2. Open cygwin shell and check signature of download:
md5sum.exe mysql-8.0.xx-winx64.zip
MD5: 9b7af5c91139659b10b84b1ca357d08f mysql-installer-community-8.0.xx1.msi
3. Update config file if you wish located here: \ProgramData\MySQL\MySQL Server 8.0\  update to include the items below
4. Run installer as admin
```
###### Method 2: Install MySQL using noinstall zip package on Windows
```

1. Download community version 8.0.xx of mysql noinstall zip (Zip ARchive) for windows from here: https://dev.mysql.com/downloads/installer/ (click archive to get previous version)
2. Open cygwin and check signature:
md5sum mysql-8.0.26-winx64.zip
> db32c0669cc809abb465bb56e76c77a1 *mysql-8.0.26-winx64.zip 
3. Update config file to at least the following.  Linux usual location is etc/my.cnf windows is usually navigate to where you downloaded package
5. Run install usr/bin/mysql_secure_installation
6. ./mysqld --defaults-file=C:\\Windows\\my.cnf --initialize
7.  ./mysql_secure_installation.exe
8. start server  ./mysqld.exe --console
```
###### Method 3: Install MySQL for Linux https://dev.mysql.com/doc/refman/8.0/en/installing-source-distribution.html
```

make sure you do not have a pre-installed version that may not be compatible with this version.
1. download community version 8.0.26 of mysql tar file from here: https://dev.mysql.com/downloads/installer/ (click archive to get previous version)
2. open cygwin and check signature:
md5sum mysql-8.0.26-el7-x86_64.tar.gz
MD5: ad605821afb685ab4bb3b3c4c66b3d86 mysql-8.0.26-el7-x86_64.tar.gz
3. Make sure prerequistes are installed: Note for red hat 8 el8 to include /lib64/kibtinfo.so.5 yum install ncurses-compat-libs
4. cd usr/local/mysql move downloaded file here and unpack:
5. gunzip mysql-8.0.26-el7-x86_64.tar.gz
6. follow commands from oracle -mysql page: https://dev.mysql.com/doc/refman/8.0/en/binary-installation.html
> groupadd mysql
> useradd -r -g mysql -s /bin/false mysql
> cd /usr/local
> tar xvf /path/to/mysql-VERSION-OS.tar.xz
> ln -s full-path-to-mysql-VERSION-OS mysql
> cd mysql
> mkdir mysql-files
> chown mysql:mysql mysql-files
> chmod 750 mysql-files
> bin/mysqld --initialize --user=mysql
> bin/mysql_ssl_rsa_setup
> bin/mysqld_safe --user=mysql &
7. Add config file see below: 
8. start mysql server: systemctl start mysqld
```


###### Method Other: Install from Yum Repository or APT
https://dev.mysql.com/doc/mysql-apt-repo-quick-guide/en/
may have to download key separately if getting an error message about missing key

### Configuration of MySQL
###### Configuration file
```

 my.cnf file and for windows add to C:Windows and for linux add to /etc/my.cnf existing. 
 replace pasword with your valid password from the MySQL install 
 and replace D:\\ with valid path to mysql data

[mysqld]
secure-file-priv = ""
port=3306
tmpdir=C:\\tmp
innodb_data_file_path = ibdata1:10M:autoextend
max_heap_table_size=214748364800
tmp_table_size=214748364800
```
###### setup config editor for ease of scripting
if added mysql as user:
mysql_config_editor set --login-path=mysql_rw --host=localhost --user=mysql --password

cat<<"EOF" | ./mysql --login-path=mysql_rw -vvv
 SET GLOBAL local_infile=1;
 SHOW GLOBAL VARIABLES LIKE 'local_infile';
EOF

###  install most recent database using the following
mysql.exe --login-path=mysql_rw -e 'create schema sofiaDB;'
mysql.exe --login-path=mysql_rw sofiaDB < tafp_mysqldump_2021*.sql

######  create dump file if you had made changes that should be kept
mysqldump --login-path=mysql_rw sofiaDB > D:/mysql/tafp_mysqldump_$(date +%Y%m%d).sql 


######  custom stored procedure
to compare status and trends data you can create the same pivoted table using mysql stored procedure: 
parameters are area code and monitoring (if included in status and trends monitoring report data)
parameters are required but can accept NULL
data is aggregated by area-stock-year as is status and trends data
This data does contain qualifiers which are eliminated with the pivot data

call tafp.sproc_get_captures(31,NULL,"C://tmp")