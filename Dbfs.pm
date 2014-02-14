package Dbfs;

use strict;
use warnings;

use Fuse;
use DBI;

use POSIX qw(:errno_h);

my $BLKSIZE = 4096;

my %TYPE = (
    file => 0100,
    directory => 0040,
);

sub getattr {
    my $path = shift;
    # Always shows current timestamp
    my $time = time();
    if ($path eq '/') {
        my $size = $BLKSIZE;
        my $blocks = 1;
        return (0, 0, $TYPE{directory} << 9 | 0755, 1, $>, $), 0, $size, $time, $time, $time, $BLKSIZE, $blocks);
    }
    my $size = _get_filesize($path);
    if (!defined $size) {
        return -POSIX::ENOENT();
    }
    my $blocks = POSIX::ceil($size / $BLKSIZE);
    return (0, 0, $TYPE{file} << 9 | 0400, 1, $>, $), 0, $size, $time, $time, $time, $BLKSIZE, $blocks);
}

sub getdir {
    my $dirname = shift;
    my ($table, $c_name, $c_size, $c_content) = @Dbfs::Config::COLUMN{qw(table filename filesize content)};
    my $dbh = dbh();
    my $sth = $dbh->prepare("SELECT $c_name FROM $table");
    $sth->execute;
    my @files;
    while (my $row = $sth->fetchrow_arrayref) {
        my $name = $row->[0];
        push @files, $name;
    }
    $sth->finish;
    $dbh->disconnect;
    return ('.', '..', @files, 0);
}

sub open {
    my ($pathname, $flags, $options) = @_;
    my ($table, $c_name, $c_size, $c_content) = @Dbfs::Config::COLUMN{qw(table filename filesize content)};
    my $size = _get_filesize($pathname);
    if (!defined $size) {
        return -POSIX::ENOENT();
    }
    return 0;
}

sub read {
    my ($pathname, $req_size, $offset, $fh) = @_;
    my $size = _get_filesize($pathname);
    if (!defined $size) {
        return -POSIX::ENOENT();
    }
    if ($size <= $offset) {
        return '';
    }
    my ($table, $c_name, $c_size, $c_content) = @Dbfs::Config::COLUMN{qw(table filename filesize content)};
    my $dbh = dbh();
    my $sth = $dbh->prepare("SELECT $c_content FROM $table WHERE $c_name = ?");
    my $path = substr $pathname, 1;
    $sth->execute($path);
    my $row = $sth->fetchrow_arrayref;
    $sth->finish;
    $dbh->disconnect;
    if (!$row) {
        return -POSIX::ENOENT();
    }
    my $content = substr $row->[0], $offset, $req_size;
    return $content;
}

sub _get_filesize {
    my $path = shift;
    my $dbh = dbh();
    my ($table, $c_name, $c_size, $c_content) = @Dbfs::Config::COLUMN{qw(table filename filesize content)};
    my $sql;
    $path = substr $path, 1;
    if (defined $c_size) {
        $sql = "SELECT $c_size FROM $table WHERE $c_name = ?";
    } else {
        $sql = "SELECT LENGTH($c_content) FROM $table WHERE $c_name = ?";
    }
    my $sth = $dbh->prepare($sql);
    $sth->execute($path);
    my $row = $sth->fetchrow_arrayref;
    $sth->finish;
    $dbh->disconnect;
    if (!$row) {
        return undef;
    }
    my $size = $row->[0];
    return $size;
}

sub dbh() {
    my ($dsn, $user, $password) = ($Dbfs::Config::DSN, $Dbfs::Config::USER, $Dbfs::Config::PASSWORD);
    my $dbh = DBI->connect($dsn, $user, $password);
    return $dbh;
}

1;

# vim: set et ts=4 sts=4 ft=perl :
