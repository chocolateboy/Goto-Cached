package Goto::Cached;

use 5.008001;

use strict;
use warnings;

use B::Hooks::OP::Check;
use B::Hooks::EndOfScope qw(on_scope_end);
use Devel::Pragma qw(my_hints);
use XSLoader;

our $VERSION = '0.20';

XSLoader::load 'Goto::Cached', $VERSION;

sub import {
    my $hints = my_hints;

    unless ($hints->{'Goto::Cached'}) {
        $hints->{'Goto::Cached'} = 1;
        on_scope_end { _leave() };
        _enter();
    }
}

sub unimport { delete my_hints->{'Goto::Cached'} }

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

Goto::Cached provides a fast, lexically-scoped drop-in replacement for Perl's
builtin C<goto>. Its use is the same as the builtin. C<goto &sub> and jumps out
of the current scope are not cached.

In a simple benchmark (see C<t/benchmark.t>), static C<goto>s are approximately 6 times
faster than the builtin, and dynamic C<goto>s are approximately 1.6 times faster.

=head1 VERSION

0.20

=head1 SEE ALSO

=over

=item * L<Acme::Goto::Line>

=back

=head1 AUTHOR

chocolateboy <chocolate@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2010, chocolateboy.

This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

=cut
