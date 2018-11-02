sql cheatsheet
===============

## Preface
Some useful tips for sql
Source: Head First SQL 


## create user

    mysql> CREATE USER 'lee'@'localhost' IDENTIFIED BY '123456';


## drop user

    (root@localhost) [(none)]> drop user lee@localhost;
    Query OK, 0 rows affected (0.07 sec)

    (root@localhost) [(none)]> grant all on *.* to lee@localhost identified by '123456';
    Query OK, 0 rows affected (0.00 sec)

## temporary table

    mysql> CREATE TEMPORARY TABLE langs ( id INT, name VARCHAR(20));
    mysql> CREATE TEMPORARY TABLE langs AS SELECT * FROM my_langs;

## foreign key

create a table with foreign key and add constraint to it

    mysql> CREATE TABLE news (
        -> id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        -> title VARCHAR(50) NOT NULL,
        -> country_id INT NOT NULL,
        -> CONSTRAINT country_id_fk
        -> FOREIGN KEY (country_id)
        -> REFERENCES COUNTRY (id)
        -> );    


## alter table

add column, primary key:

    mysql> ALTER TABLE countries ADD COLUMN id INT NOT NULL AUTO_INCREMENT FIRST, ADD PRIMARY KEY (id);


## the case operator    

you know what, there is `case` expressions in SQL

    mysql> SELECT president, 
                  CASE 
                    WHEN LENGTH(president) < 5 THEN 'short' 
                    ELSE 'too long a name'
                  END AS is_it_good
                  FROM country;
    +-----------+-----------------+
    | president | is_it_good      |
    +-----------+-----------------+
    | Xi        | short           |
    | Abe       | short           |
    | Obama     | too long a name |
    +-----------+-----------------+
    3 rows in set (0.00 sec)

    

## subqueries vs. joins

subqueries can be replaced by joins, for example, find countries which has some news:

    select * from country c where exists (select * from news where news.country_id = c.id);

    select c.* from country c left join news n on c.id = n.country_id where n.id is not null;


## views

`with check option` ensures that only values match the view can be inserted or updated through this view

    mysql> create view asia_countries as select * from country where continent = 'Asia' with check option;


## privileges

    mysql> show grants for 'lee'@'localhost';

create user and grant privileges in a single command:

    mysql> grant select on test.country to 'foo'@'localhost' identified by 'hello';

revoke privileges:

    mysql> revoke select on test.country from 'foo'@'localhost';


## auto increment

alter a table's auto_increment starting number

    alter table my_table auto_increment = 1000000;

## convert datetime between timezones

    select CONVERT_TZ('2015-11-28 16:39:34', '+0:00', @@session.time_zone);
        +-----------------------------------------------------------------+
        | CONVERT_TZ('2015-11-28 16:39:34', '+0:00', @@session.time_zone) |
        +-----------------------------------------------------------------+
        | 2015-11-29 05:39:34                                             |
        +-----------------------------------------------------------------+
        1 row in set (0.00 sec)
