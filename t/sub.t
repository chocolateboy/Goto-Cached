#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;
use Data::Dumper;
use Goto::Cached;

sub test1 {
    goto &test2;
}

sub test2 {
    return [ caller(0) ];
}

sub test3 {
    goto shift;
}

sub test4 {
    return [ caller(0) ];
}

my ($caller1, $caller2) = (test1(), test2());
my ($caller3, $caller4) = (test3(\&test4), test4());

is(Dumper($caller1),       Dumper($caller2));
is(Dumper($caller3),       Dumper($caller4));
is(Dumper(test1()),        Dumper(test2()));
is(Dumper(test3(\&test4)), Dumper(test4()));
