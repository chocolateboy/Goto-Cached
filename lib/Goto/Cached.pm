package Goto::Cached;

use 5.008008;

use strict;
use warnings;

use B::Hooks::OP::Annotation;
use B::Hooks::OP::Check;
use B::Hooks::EndOfScope qw(on_scope_end);
use Devel::Pragma qw(my_hints);
use XSLoader;

our $VERSION = '0.22';

XSLoader::load 'Goto::Cached', $VERSION;

sub import {
    my $hints = my_hints;

    unless ($hints->{'Goto::Cached'}) {
        $hints->{'Goto::Cached'} = 1;
        on_scope_end \&_leave;
        _enter();
    }
}

sub unimport { delete my_hints->{'Goto::Cached'} }

1;

__END__

=head1 NAME

Goto::Cached - a fast drop-in replacement for Perl's O(n) goto

=head1 SYNOPSIS

    sub factorial($) {
        use Goto::Cached;
        my $n = shift;
        my $accumulator = 1;

        iter: return $accumulator if ($n < 2);
        $accumulator *= $n;
        --$n;
        goto iter;
    }

=head1 DESCRIPTION

Goto::Cached provides a fast, lexically-scoped drop-in replacement for Perl's
builtin C<goto>. Its use is the same as the builtin. C<goto &sub> and jumps out
of the current scope (including C<if> and C<unless> blocks) are not cached.

=head1 VERSION

0.22

=head1 SEE ALSO

=over

=item * L<Acme::Goto::Line>

=back

=head1 AUTHOR

chocolateboy <chocolate@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005-2010 by chocolateboy.

This is free software; you can redistribute it and/or modify it under the
terms of the Artistic License 2.0.
