#!/usr/bin/env perl

# run the test suite with PERL_TEST_GOTO_CACHED_DISABLE_BENCHMARK set to disable this benchmark e.g.
#
#     PERL_TEST_GOTO_CACHED_DISABLE_BENCHMARK=1 make test

use strict;
use warnings;

use Test::More;

sub cached_factorial($) {
    use Goto::Cached;
    my $n = shift;
    my $accum = 1;

    iter: return $accum if ($n < 2);
    $accum *= $n;
    --$n;
    goto iter;
}

sub uncached_factorial($) {
    my $n = shift;
    my $accum = 1;

    iter: return $accum if ($n < 2);
    $accum *= $n;
    --$n;
    goto iter;
}

sub loop_factorial($) {
    my $accum = 1;
    my $n = shift;

    while ($n > 1) {
        $accum *= $n;
        --$n;
    }

    return $accum;
}

sub recursive_factorial($);
sub recursive_factorial($) {
    my $n = shift;

    if ($n < 2) {
        return 1;
    } else {
        return $n * recursive_factorial($n - 1);
    }
}

my $N = 15;
my $N_FACTORIAL = 1_307_674_368_000;
my $COUNT = -2;

for (qw(uncached_factorial cached_factorial loop_factorial recursive_factorial)) {
    my $got = __PACKAGE__->can($_)->($N);
    my $want = $N_FACTORIAL;

    unless ($got == $want) {
        plan skip_all => "invalid result for $_: expected $want, got $got";
    }
}

if ($ENV{'PERL_TEST_GOTO_CACHED_DISABLE_BENCHMARK'}) {
    plan skip_all => 'benchmark disabled';
} elsif (eval "use App::Benchmark; 1") {
    benchmark_diag($COUNT, {
        uncached_factorial  => sub { uncached_factorial($N) },
        cached_factorial    => sub { cached_factorial($N) },
        loop_factorial      => sub { loop_factorial($N) },
        recursive_factorial => sub { recursive_factorial($N) },
    });
    done_testing;
} else {
    plan skip_all => 'App::Benchmark is not installed';
}
