#!/usr/bin/env perl

# run the test suite with PERL_TEST_GOTO_CACHED_DISABLE_BENCHMARK set to disable this benchmark e.g.
#
#     PERL_TEST_GOTO_CACHED_DISABLE_BENCHMARK=1 make test

use strict;
use warnings;

use Test::More;

sub static_cached {
    use Goto::Cached;
    my $i = 0;
    goto LABEL9;

    ++$i;
    ++$i;
    ++$i;
    ++$i;
    ++$i;
    ++$i;
    ++$i;
    ++$i;
    ++$i;
    ++$i;

    LABEL0: return;
    LABEL1: goto LABEL0;
    LABEL2: goto LABEL1;
    LABEL3: goto LABEL2;
    LABEL4: goto LABEL3;
    LABEL5: goto LABEL4;
    LABEL6: goto LABEL5;
    LABEL7: goto LABEL6;
    LABEL8: goto LABEL7;
    LABEL9: goto LABEL8;
}

sub static_uncached {
    my $i = 0;
    goto LABEL9;

    ++$i;
    ++$i;
    ++$i;
    ++$i;
    ++$i;
    ++$i;
    ++$i;
    ++$i;
    ++$i;
    ++$i;

    LABEL0: return;
    LABEL1: goto LABEL0;
    LABEL2: goto LABEL1;
    LABEL3: goto LABEL2;
    LABEL4: goto LABEL3;
    LABEL5: goto LABEL4;
    LABEL6: goto LABEL5;
    LABEL7: goto LABEL6;
    LABEL8: goto LABEL7;
    LABEL9: goto LABEL8;
}

sub dynamic_cached {
    use Goto::Cached;
    my $i = 0;
    my $label0 = 'LABEL0';
    my $label1 = 'LABEL1';
    my $label2 = 'LABEL2';
    my $label3 = 'LABEL3';
    my $label4 = 'LABEL4';
    my $label5 = 'LABEL5';
    my $label6 = 'LABEL6';
    my $label7 = 'LABEL7';
    my $label8 = 'LABEL8';
    my $label9 = 'LABEL9';

    goto $label9;

    ++$i;
    ++$i;
    ++$i;
    ++$i;
    ++$i;
    ++$i;
    ++$i;
    ++$i;
    ++$i;
    ++$i;

    LABEL0: return;
    LABEL1: goto $label0;
    LABEL2: goto $label1;
    LABEL3: goto $label2;
    LABEL4: goto $label3;
    LABEL5: goto $label4;
    LABEL6: goto $label5;
    LABEL7: goto $label6;
    LABEL8: goto $label7;
    LABEL9: goto $label8;
}

sub dynamic_uncached {
    my $i = 0;
    my $label0 = 'LABEL0';
    my $label1 = 'LABEL1';
    my $label2 = 'LABEL2';
    my $label3 = 'LABEL3';
    my $label4 = 'LABEL4';
    my $label5 = 'LABEL5';
    my $label6 = 'LABEL6';
    my $label7 = 'LABEL7';
    my $label8 = 'LABEL8';
    my $label9 = 'LABEL9';

    goto $label9;

    ++$i;
    ++$i;
    ++$i;
    ++$i;
    ++$i;
    ++$i;
    ++$i;
    ++$i;
    ++$i;
    ++$i;

    LABEL0: return;
    LABEL1: goto $label0;
    LABEL2: goto $label1;
    LABEL3: goto $label2;
    LABEL4: goto $label3;
    LABEL5: goto $label4;
    LABEL6: goto $label5;
    LABEL7: goto $label6;
    LABEL8: goto $label7;
    LABEL9: goto $label8;
}

if ($ENV{'PERL_TEST_GOTO_CACHED_DISABLE_BENCHMARK'}) {
    plan skip_all => 'benchmark disabled';
} elsif (eval "use App::Benchmark; 1") {
    benchmark_diag(-2, {
        dynamic_cached   => \&dynamic_cached,
        dynamic_uncached => \&dynamic_uncached,
        static_cached    => \&static_cached,
        static_uncached  => \&static_uncached,
    });
    done_testing;
} else {
    plan skip_all => 'App::Benchmark is not installed';
}
