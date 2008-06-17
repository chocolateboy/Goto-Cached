package Goto::Cached;

use 5.006;

use strict;
use warnings;

use XSLoader;
use Scope::Guard;
use Devel::Hints::Lexical qw(lexicalize_hh);

our $VERSION = '0.09';

XSLoader::load 'Goto::Cached', $VERSION;

sub import {
    my $class = shift;
    my $guard = Scope::Guard->new(\&_leave);

    lexicalize_hh;

    $^H{'Goto::Cached'} = 1;
    $^H{$guard} = $guard;

    _enter();
}

1;

__END__

=head1 NAME

Goto::Cached - a fast drop-in replacement for Perl's O(n) goto

=head1 SYNOPSIS

    use Goto::Cached;

    my $label = 'LABEL3';

    goto LABEL1;

    LABEL1: goto $label;

    LABEL2: print "Not reached!", $/;

    LABEL3: print "label3!", $/;

=head1 DESCRIPTION

Goto::Cached provides a fast, lexically-scoped drop-in replacement for perl's
builtin C<goto>. Its use is the same as the builtin. C<goto &sub> and jumps out
of the current scope are not cached.

=head1 VERSION

0.09

=head1 SEE ALSO

=over

=item * L<Acme::Goto::Line>

=back

=head1 AUTHOR

chocolateboy <chocolate.boy@email.com>

=head1 COPYRIGHT

Copyright (c) 2005-2008, chocolateboy.

This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

=cut
