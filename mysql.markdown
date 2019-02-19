# MySQL cheatsheet

- [Preface](#preface)
- [`mysql`](#mysql)
- [`mysqladmin`](#mysqladmin)
- [Storage engines](#storage-engines)
  - [MyISAM](#myisam)
  - [Innodb](#innodb)
  - [CSV](#csv)
- [权限级别](#%E6%9D%83%E9%99%90%E7%BA%A7%E5%88%AB)
- [Data backup and recovery](#data-backup-and-recovery)
  - [Logical backup](#logical-backup)
  - [Data recovery](#data-recovery)
- [Query optimization](#query-optimization)
  - [GROUP BY](#group-by)
  - [profiling](#profiling)
- [Schema 设计优化](#schema-%E8%AE%BE%E8%AE%A1%E4%BC%98%E5%8C%96)
- [Transaction isolation levels](#transaction-isolation-levels)
- [Locking](#locking)
- [Lock problems](#lock-problems)
- [Install MySQL from source](#install-mysql-from-source)
  - [Multiple MySQL server instances on one machine](#multiple-mysql-server-instances-on-one-machine)
- [Timezone](#timezone)
- [Quick recipes](#quick-recipes)
  - [Search and replace text](#search-and-replace-text)
  - [Duplicate records in a table](#duplicate-records-in-a-table)
  - [MySQL strict mode](#mysql-strict-mode)

## Preface

Some useful tips for MySQL

Source: Head First SQL

## `mysql`

Set mysql prompt in an option file, such as `~/.my.cnf`

    [mysql]
    prompt=(\\u@\\h) [\\d]>\\_

Edit sql at command line: use `edit` command to open an editor to do this

## `mysqladmin`

Ping the server

```sh
mysqladmin -ugary -pmypass ping
# mysqld is alive
```

Server status

```sh
mysqladmin -ugary -pmypass status
# Uptime: 10887  Threads: 2  Questions: 238  Slow queries: 0  Opens: 179  Flush tables: 1  Open tables: 43  Queries per second avg: 0.021
```

Process list

```sh
mysqladmin -ugary -pmypass processlist
# +----+------+-----------+----+---------+------+-------+------------------+
# | Id | User | Host      | db | Command | Time | State | Info             |
# +----+------+-----------+----+---------+------+-------+------------------+
# | 63 | gary | localhost |    | Query   | 0    |       | show processlist |
# +----+------+-----------+----+---------+------+-------+------------------+
```

## Storage engines

### MyISAM

For each table, there are three files:

- .frm -> table schema
- .MYD -> data
- .MYI -> index

Three indexing method:

- B-tree -> all index data at leaf nodes
- R-tree -> only support geometry type
- Full-text -> also B-tree, 解决 like 查询的低效问题

数据存放格式:

- FIXED -> all fields have fixed length
- DYNAMIC -> if any variable length field presents
- COMPRESSED

### Innodb

- 事务支持
- 锁定机制改进, 支持行锁 (行锁的并发比 MyISAM 的表锁要好)
- 实现外键

数据存储:

数据和索引存放在一起,

- 共享表空间: 多表共用同一个(或多个)文件
- 独享表空间: 每个表单独对应一个.idb 文件

### CSV

Data are stored in a '.csv' file

```sh
(root@localhost) [test]> create table hellocsv ( id int(10) not null, name varchar(16) not null ) engine=csv;
#   Query OK, 0 rows affected (0.12 sec)

(root@localhost) [test]> insert into hellocsv values(1, 'gary'),(2, 'wang');
#   Query OK, 2 rows affected (0.08 sec)
#   Records: 2  Duplicates: 0  Warnings: 0

(root@localhost) [test]> select * from hellocsv;
#   +----+------+
#   | id | name |
#   +----+------+
#   |  1 | gary |
#   |  2 | wang |
#   +----+------+
#   2 rows in set (0.00 sec)
```

Show content of the data file

```sh
cat hellocsv.CSV
#   1,"gary"
#   2,"wang"
```

## 权限级别

高级别覆盖低级别

- Global
- Database
- Table

  ALTER, CREATE, DELETE, DROP, INDEX, INSERT, SELECT, UPDATE

  ```sql
  GRANT INDEX ON test.t1 TO 'abc'@'%.jianzhaoyang.com';
  ```

- Column

  INSERT, SELECT, UPDATE

  ```sql
  GRANT SELECT(id,value) ON test.t2 TO 'abc'@'%.jianzhaoyang.com';
  ```

- Routine

  EXECUTE, ALTER ROUTINE

  ```sql
  GRANT EXECUTE ON test.p1 to 'abc'@'localhost';
  ```

## Data backup and recovery

### Logical backup

- `mysqldump`

  **数据可能不一致**

  useful options: `--single-transcation`, `--lock-tables`, `--lock-all-tables`, `--no-data`, `--where` (when dump a single table)

  ```sql
  /* `-t` for only dumping data, no structure */
  mysqldump -ugary -p test -t --table news > news.sql
  ```

- CSV file

  Save data to a file: `SELECT * INTO OUTFILE 'file-path' FROM ...`

  ```sql
  SELECT * FROM country;
  /*
  +----+-----------+---------------+-----------+
  | id | name      | continent     | president |
  +----+-----------+---------------+-----------+
  |  1 | zhongguo  | Asia          | Xi        |
  |  3 | US        | North America | Obama     |
  |  4 | UK        | Europe        | Cameron   |
  | 10 | Japan     | Asia          | Abe       |
  +----+-----------+---------------+-----------+
  4 rows in set (0.00 sec)
  */

  SELECT * INTO OUTFILE '/tmp/country.out' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' FROM country;
  /*
  Query OK, 5 rows affected (0.00 sec)
  */
  ```

  ```sh
  cat /tmp/country.out
  #     1,"zhongguo","Asia","Xi"
  #     3,"US","North America","Obama"
  #     4,"UK","Europe","Cameron"
  #     10,"Japan","Asia","Abe"
  ```

  Or, use `mysqldump`, this will generate table structure and data in different files

  ```sh
  mysqldump -uroot -p -T/tmp test country --fields-enclosed-by='"' --fields-terminated-by=,

  ll /tmp/country.*
  #     -rw-r--r-- 1 root  root  1485 Sep  7 17:18 /tmp/country.sql
  #     -rw-rw-rw- 1 mysql mysql  143 Sep  7 17:18 /tmp/country.txt

  cat /tmp/country.sql
  #     ...
  #
  #     --
  #     -- Table structure for table `country`
  #     --
  #
  #     DROP TABLE IF EXISTS `country`;
  #     /*!40101 SET @saved_cs_client     = @@character_set_client */;
  #     /*!40101 SET character_set_client = utf8 */;
  #     CREATE TABLE `country` (
  #       `id` int(11) NOT NULL AUTO_INCREMENT,
  #       `name` varchar(20) NOT NULL,
  #       `continent` varchar(16) DEFAULT NULL,
  #       `president` varchar(30) NOT NULL,
  #       PRIMARY KEY (`id`)
  #     ) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=latin1;
  #     /*!40101 SET character_set_client = @saved_cs_client */;
  #
  #     ...

  cat /tmp/country.txt
  #     "1","zhongguo","Asia","Xi"
  #     "3","US","North America","Obama"
  #     "4","UK","Europe","Cameron"
  #     "10","Japan","Asia","Abe"
  ```

### Data recovery

Load data file to table:

```sh
mysqlimport --user=name --password=pwd test --fields-enclosed-by='"' --fields-terminated-by=, /tmp/test_outfile.txt
```

OR

```sql
LOAD DATA INFILE '/tmp/test_outfile.txt' INTO TABLE test_outfile FIELDS TERMINATED BY '"' ENCLOSED BY ',';
```

## Query optimization

基本思路和原则:

1. 优化更需要优化的 Query;
2. 定位优化对象的性能瓶颈;
3. 明确的优化目标;
4. 从 EXPLAIN 入手;
5. 多使用 profiling;
6. 永远用小结果集驱动大的结果集;
7. 尽可能在索引中完成排序;
8. 只取出自己需要的 Columns;
9. 仅仅使用最有效的过滤条件;
10. 尽可能避免复杂的 JOIN 和子查询;
    - 复杂的 JOIN 占用资源多，可能需要等待或者会让其它线程等待，可能比多个简单的查询还慢;
    - Mysql 对子查询的优化不佳，可能有索引而没被利用;

### GROUP BY

**在优化 GROUP BY 的时候还有一个小技巧可以让我们在有些无法利用到索引的情况下避免 filesort 操作,也就是在整个语句最后添加一个以 null 排序(ORDER BY null)的子句**

```sql
(root@localhost) [test]> explain select * from news group by rate;
/*
+----+-------------+-------+------+---------------+------+---------+------+------+---------------------------------+
| id | select_type | table | type | possible_keys | key  | key_len | ref  | rows | Extra                           |
+----+-------------+-------+------+---------------+------+---------+------+------+---------------------------------+
|  1 | SIMPLE      | news  | ALL  | NULL          | NULL | NULL    | NULL |    5 | Using temporary; Using filesort |
+----+-------------+-------+------+---------------+------+---------+------+------+---------------------------------+
1 row in set (0.00 sec)
*/

(root@localhost) [test]> explain select * from news group by rate order by null;
/*
+----+-------------+-------+------+---------------+------+---------+------+------+-----------------+
| id | select_type | table | type | possible_keys | key  | key_len | ref  | rows | Extra           |
+----+-------------+-------+------+---------------+------+---------+------+------+-----------------+
|  1 | SIMPLE      | news  | ALL  | NULL          | NULL | NULL    | NULL |    5 | Using temporary |
+----+-------------+-------+------+---------------+------+---------+------+------+-----------------+
1 row in set (0.00 sec)
*/
```

### profiling

```sql
/* enable profiling */
(root@localhost) [test]> SET profiling=1;
/*
Query OK, 0 rows affected (0.00 sec)
*/

(root@localhost) [test]> SELECT * FROM country;
/*
+----+-----------+---------------+-----------+
| id | name      | continent     | president |
+----+-----------+---------------+-----------+
|  1 | zhongguo  | Asia          | Xi        |
|  3 | US        | North America | Obama     |
|  4 | UK        | Europe        | Cameron   |
| 10 | Japan     | Asia          | Abe       |
+----+-----------+---------------+-----------+
4 rows in set (0.00 sec)
*/

/* show profiling info */
(root@localhost) [test]> SHOW PROFILES;
/*
+----------+------------+-----------------------+
| Query_ID | Duration   | Query                 |
+----------+------------+-----------------------+
|        1 | 0.00008700 | select * from country |
+----------+------------+-----------------------+
1 row in set (0.00 sec)
*/

/* detail info for a query */
(root@localhost) [test]> SHOW PROFILE cpu, block io FOR query 1;
/*
+--------------------------------+----------+----------+------------+--------------+---------------+
| Status                         | Duration | CPU_user | CPU_system | Block_ops_in | Block_ops_out |
+--------------------------------+----------+----------+------------+--------------+---------------+
| starting                       | 0.000029 | 0.004000 |   0.000000 |            0 |             0 |
| Waiting for query cache lock   | 0.000006 | 0.000000 |   0.000000 |            0 |             0 |
| checking query cache for query | 0.000009 | 0.000000 |   0.000000 |            0 |             0 |
| checking privileges on cached  | 0.000006 | 0.000000 |   0.000000 |            0 |             0 |
| checking permissions           | 0.000010 | 0.000000 |   0.000000 |            0 |             0 |
| sending cached result to clien | 0.000016 | 0.000000 |   0.000000 |            0 |             0 |
| logging slow query             | 0.000006 | 0.000000 |   0.000000 |            0 |             0 |
| cleaning up                    | 0.000006 | 0.000000 |   0.000000 |            0 |             0 |
+--------------------------------+----------+----------+------------+--------------+---------------+
8 rows in set (0.00 sec)
*/
```

## Schema 设计优化

- 适度冗余 - 让 Query 尽量减少 Join

  如在帖子表存储用户昵称, 这样用户更新昵称的时候要更新多个表，但用户更新昵称是个不频繁的操作

- 大字段垂直分拆

  将访问频率低的大字段分拆成独立的表, 如帖子表中分离出帖子的内容为单独的表

- 大表水平分拆 - 基于类型的分拆优化

- 统计表 - 准实时优化

  通过定时统计数据来替代实时统计查询

## Transaction isolation levels

- READ UNCOMMITTED

  trx A can read uncommitted data from trx B, can cause dirty read

- READ COMMITTED

  trx A can read committed data from trx B, can cause read-not-repeatable, violates I (isolation) of ACID

- REPEATABLE READ

  what trx A reads is not affected by other trx (always the same in a trx), default setting for InnoDB in MySQL

## Locking

Levels:

- row-level

  - 粒度小，并发高，获取锁资源消耗大，易死锁;
  - Innodb

- table-level

  - 粒度大，并发低，获取锁资源消耗少;
  - MyISAM, Memory, CSV

- page-level

  - 介于上面二者之间;
  - BerkeleyDB

## Lock problems

- 丢失更新 (lost update)

  - 读取数据时加上 X 锁

    ```sql
    SELECT cash INTO @cash FROM account WHERE user = pUser FOR UPDATE;
    ```

- 脏读

  - 事务隔离级别为 READ UNCOMMITTED 会产生，隔离级别为 READ COMMITTED 时不会有该问题;

- 不可重复读

  - 同一事务中相同查询多次运行的结果不一样;
  - 事务隔离级别为 READ COMMITTED 会产生，隔离级别为 REPEATABLE READ 时不会有该问题;

## Install MySQL from source

ref: http://dev.mysql.com/doc/refman/5.6/en/installing-source-distribution.html

- Download the source tar ball from mysql.com

- Install configure/compile tools

  ```sh
  sudo apt-get install cmake
  ```

- Configure / compile / install

  ```sh
  tar xzf mysql-5.6.15.tar.gz
  cd mysql-5.6.15/

  # configure, specify installation base directory, all options available through 'cmake . -LAH'
  cmake . -DCMAKE_INSTALL_PREFIX=/opt/mysql

  # compile and install
  make
  sudo make install DESTDIR="/opt/mysql"
  ```

- Post installation steps

  ```sh
  # create a link
  cd /opt
  sudo mv mysql/ mysql-5.6.15
  sudo ln -s mysql-5.6.15/ mysql

  cd mysql
  sudo chown -R mysql:mysql .

  # use the '--no-defaults' flag to suppress using default conf file
  sudo ./scripts/mysql_install_db --user=mysql --no-defaults

  sudo chown -R root .
  sudo chown -R mysql data

  # edit the config file, start the server
  sudo bin/mysqld_safe --defaults-file=my-new.cnf
  ```

### Multiple MySQL server instances on one machine

Continue from above:

```sh
cd /opt/mysql
sudo mkdir conf
cd conf/

# create a conf file
sudo vi my.3364.cnf

# [client]
# port = 3364
# socket = /var/run/mysqld/mysqld.3364.sock
#
#
# [mysqld]
# user = mysql
# basedir = /opt/mysql
# datadir = /data/mysql/data1
# port = 3364
# socket = /var/run/mysqld/mysqld.3364.sock
# pid-file = /var/run/mysqld/mysqld.3364.pid

# create data directory
sudo mkdir /data/mysql/data1

# init db
cd /opt/mysql
sudo ./scripts/mysql_install_db --defaults-file=conf/my.3364.cnf

# start server
sudo ./bin/mysqld_safe --defaults-file=conf/my.3364.cnf

# connect to server (default pass is empty)
mysql --defaults-file=/opt/mysql/conf/my.3364.cnf -uroot -p
```

Repeat above steps for more mysql server instances

**OR, use `mysqld_multi` to manage multiple instances**

## Timezone

Timezone variables:

- `system_time_zone`: default to system timezone setting, can not be changed;
- `global.time_zone`: default to 'SYSTEM';
- `session.time_zone`: default to `global.time_zone`, can be changed per session, results of `now()` depend on this;

```sql
MYSQL> select @@system_time_zone;
/*
+--------------------+
| @@system_time_zone |
+--------------------+
| NZDT               |
+--------------------+
*/

MYSQL> select @@global.time_zone;
/*
+--------------------+
| @@global.time_zone |
+--------------------+
| SYSTEM             |
+--------------------+
*/

MYSQL> select @@session.time_zone;
/*
+---------------------+
| @@session.time_zone |
+---------------------+
| SYSTEM              |
+---------------------+
*/

MYSQL> set session time_zone = '+08:00'; select now();
/*
+---------------------+
| now()               |
+---------------------+
| 2015-12-06 08:54:46 |
+---------------------+
*/

MYSQL> set session time_zone = 'SYSTEM'; select now();
/*
+---------------------+
| now()               |
+---------------------+
| 2015-12-06 13:54:58 |
+---------------------+
*/
```

## Quick recipes

### Search and replace text

Use the `REPLACE` function, all occurence will be replaced:

```sql
UPDATE news SET title = REPLACE(title, 'hello', 'hola') WHERE id = 2;
```

Update values encoded by base64 (`TO_BASE64` and `FROM_BASE64` are added after MySQL 5.6):

```sql
UPDATE my_table SET meta_value = TO_BASE64(REPLACE(FROM_BASE64(meta_value), 'xxx', 'yyy'));
```

### Duplicate records in a table

```sql
CREATE TEMPORARY TABLE tmp_table SELECT * FROM table_name;
ALTER TABLE tmp_table DROP id;
INSERT INTO table_name SELECT 0, tmp_table.* FROM tmp_table;
DROP TABLE tmp_table;
```

### MySQL strict mode

MySQL introduced 'strict' mode from v5.6, to turn it off, add the following line under `[mysqld]` in `my.cnf`

```
sql_mode=""
```
