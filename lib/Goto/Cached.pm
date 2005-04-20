package Goto::Cached;

use 5.006;

use strict;
use warnings;

use XSLoader;
use Scope::Guard;

our $VERSION = '0.04';

XSLoader::load 'Goto::Cached', $VERSION;

sub import {
	my $sg = Scope::Guard->new(sub { Goto::Cached::leavescope() });

	$^H |= 0x220000; # 0x220000 rather than 0x020000 to work around %^H scoping bug
	$^H{'Goto::Cached'} = 1;
	$^H{$sg} = $sg;

	Goto::Cached::enterscope();
}

END { Goto::Cached::cleanup() }

1;

__END__

=head1 NAME

Goto::Cached - an amortized O(1) drop-in replacement for Perl's O(n) goto

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

0.04

=head1 SEE ALSO

L<Acme::Goto::Line>

=head1 AUTHOR

chocolateboy: <chocolate.boy@email.com>

=head1 COPYRIGHT

Copyright (c) 2005, chocolateboy.

This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

=cut
