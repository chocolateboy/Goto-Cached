# Goto::Cached

[![CPAN Version](https://badge.fury.io/pl/autobox.svg)](http://badge.fury.io/pl/autobox)
[![License](https://img.shields.io/badge/license-artistic-blue.svg)](https://github.com/chocolateboy/autobox/blob/master/LICENSE.md)

# NAME

Goto::Cached - a fast drop-in replacement for Perl's O(n) goto

# SYNOPSIS

```perl
sub factorial($) {
    use Goto::Cached;
    my $n = shift;
    my $accumulator = 1;

    iter: return $accumulator if ($n < 2);
    $accumulator *= $n;
    --$n;
    goto iter;
}
```

# DESCRIPTION

Goto::Cached provides a fast, lexically-scoped drop-in replacement for Perl's
builtin `goto`. Its use is the same as the builtin. `goto &sub` and jumps out
of the current scope (including `if` and `unless` blocks) are not cached.

# VERSION

0.22

# SEE ALSO

* [Acme::Goto::Line](https://metacpan.org/pod/Acme::Goto::Line)

# AUTHOR

[chocolateboy](mailto:chocolate@cpan.org)

# COPYRIGHT

Copyright © 2005-2010 by chocolateboy.

This is free software; you can redistribute it and/or modify it under the terms of the
[Artistic License 2.0](http://www.opensource.org/licenses/artistic-license-2.0.php).
