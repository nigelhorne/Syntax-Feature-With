# NAME

Syntax::Feature::With - Lightweight lexical aliasing with strict/debug/trace modes

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

# LIMITATIONS

- Lexicals must be declared in the outer scope.
- Only hashrefs are supported.
- Only keys matching `/^[A-Za-z_]\w*$/` are eligible.

# AUTHOR

Nigel Horne

# LICENSE

Same terms as Perl itself.
