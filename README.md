# Dbfs

## What is this?

Dbfs is a filesystem that has database as a backend storage.

## Usage

    # To mount:
    $ dbfs
    --dsn DSN
    --user DB_USER
    --password DB_PASS
    --table DB_TABLE
    --filename-column FILENAME_COLUMN
    [--filesize-column FILESIZE_COLUMN]
    --content-column CONTENT_COLUMN
    [--debug | -d]
    mountpoint

    $ dbfs [--help | -h | -?]

    # To unmount:
    fusermount -u mountpoint

# Sample

## Database DDL (MySQL)

    CREATE TABLE `files` (
      `name` varchar(128) CHARACTER SET utf8 DEFAULT NULL,
      `content` blob,
      `size` int(11) DEFAULT NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8

## Content

    > select * from files;
    +------+---------+------+
    | name | content | size |
    +------+---------+------+
    | a    | abcde   |    5 |
    | b    | fghji   |    5 |
    +------+---------+------+
    
## Mount

    dbfs --dsn='dbi:mysql:database=database_name:hostname=db_hostname'
         --user db_user --password db_pass --table files
         --filename-column name --filesize-column size --content-column content
         mountpoint_dir

----

# Changelog

* 2014/Feb/21 first release

