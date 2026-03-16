# NAME

Syntax::Feature::With - Simulate Pascal's "with" statement in Perl

# SYNOPSIS

    use Syntax::Feature::With qw(with with_hash);

    my %h = ( a => 1, b => 2 );
    my ($a, $b);

    # Basic usage
    with \%h, sub {
        say $a;   # 1
        $b = 99;  # updates %h
    };

    # Strict mode
    with -strict => \%h, sub {
        say $a;   # ok
        say $b;   # ok
        say $c;   # error: undeclared
    };

    # Debug mode
    with -debug => \%h, sub {
        ...
    };

    # Trace mode (includes debug)
    with -trace => \%h, sub {
        ...
    };

    # Convenience wrapper
    with_hash %h => sub {
        say $a;
    };

# DESCRIPTION

`with()` provides a simple, predictable way to temporarily alias hash
keys into lexical variables inside a coderef. It is implemented using
[PadWalker](https://metacpan.org/pod/PadWalker) and requires no XS, no parser hooks, and no syntax changes.

# FEATURES

## Read/write aliasing

Lexicals declared in the outer scope become aliases to hash entries:

    my ($a);
    with \%h, sub { $a = 10 };   # updates $h{a}

## Strict mode

    with -strict => \%h, sub { ... };

Every valid hash key must have a matching lexical declared in the outer
scope. Missing lexicals cause an immediate error.

## Debug mode

    with -debug => \%h, sub { ... };

Prints a summary of aliasing decisions:

    Aliased: $a -> %hash{a}
    Ignored: foo-bar (invalid identifier)
    Ignored: y (no lexical declared)

## Trace mode

    with -trace => \%h, sub { ... };

Shows entry/exit and nesting depth:

    [with depth=1] entering with()
    Aliased: $a -> %hash{a}
    [with depth=1] leaving with()

Trace mode implies debug mode.

## Nested with() support

Nested calls work naturally:

    with \%h1, sub {
        with \%h2, sub {
            ...
        };
    };

## with\_hash wrapper

Syntactic sugar:

    with_hash %h => sub { ... };

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# LIMITATIONS

- Lexicals must be declared in the outer scope.
- Only hashrefs are supported.
- Only keys matching `/^[A-Za-z_]\w*$/` are eligible.

# AUTHOR

Nigel Horne

# LICENSE

Same terms as Perl itself.

# REPOSITORY

[https://github.com/nigelhorne/Syntax-Feature-With](https://github.com/nigelhorne/Syntax-Feature-With)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-syntax-feature-with at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Syntax-Featre-With](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Syntax-Featre-With).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Syntax-Feature-With

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/Syntax-Featre-With](https://metacpan.org/dist/Syntax-Featre-With)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Syntax-Featre-With](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Syntax-Featre-With)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Syntax-Featre-With](http://matrix.cpantesters.org/?dist=Syntax-Featre-With)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Syntax-Featre-With](http://deps.cpantesters.org/?module=Syntax-Featre-With)

# LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
