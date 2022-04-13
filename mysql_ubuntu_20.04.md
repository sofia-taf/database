# Instructions for Ubuntu 20.04

## 1 Install MySQL

```
$ sudo apt install mysql
```

(installs MySQL 8.0.28)

```
$ systemctl start mysql.service
$ sudo mysql_secure_installation

  validate password component = y
  level of password validation = 2 (strong)
  new password: Fao_2022
  remove anonymous = yes
  disallow root login remotely = y
  remove test database = y
  reload privilege tables = y

$ sudo mysql
> CREATE USER 'mysql'@'localhost' IDENTIFIED WITH mysql_native_password BY 'Fao_2022';
> QUIT
$ mysql_config_editor set --login-path=mysql_rw --host=localhost --user=mysql --password
```

## 2 Test MySQL

```
$ mysql --login-path=mysql_rw -e 'SELECT 1;'
```

## 3  Grant privileges

```
$ sudo mysql
> GRANT ALL PRIVILEGES ON *.* TO 'mysql'@'localhost';
> QUIT
```

## 4 Create database

```
$ mysql --login-path=mysql_rw -e 'CREATE SCHEMA tafp;'
> SHOW SCHEMAS;
> QUIT
$ mysql --login-path=mysql_rw tafp < tafp_backup_20220109.sql
> SELECT * FROM tafp.area;
> QUIT
```

## 5 Install MySQL Workbench

Open https://dev.mysql.com/downloads/workbench/ in a browser, select OS and download

```
$ sudo apt install ./mysql-workbench-community_8.0.28-1ubuntu20.04_amd64.deb
```
