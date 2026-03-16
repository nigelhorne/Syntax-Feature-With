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

## with\_hash

    with_hash \%hash, sub {
        say $foo;     # reads $hash{foo}
        $bar = 123;   # writes to $hash{bar}
    };

    with_hash strict => a => 1, b => 2, sub {
        ...
    };

Execute a block with temporary lexical aliases to the keys of a hash.

`with_hash` provides a convenient way to work with a hash by exposing each
key as a lexical variable inside a coderef. Reads and writes to those
lexicals operate directly on the underlying hash, making the block feel like
it has named parameters or local variables without the usual unpacking
boilerplate.

This is syntactic sugar around `with()`, normalizing the arguments and
ensuring that the hash and coderef are parsed correctly.

### Arguments

`with_hash` accepts the following forms:

- Optional flags

    One or more strings that modify behaviour (e.g. `strict`, `debug`).
    Flags must appear first.

- A hash reference

        with_hash \%h, sub { ... };

- A hash list

        with_hash a => 1, b => 2, sub { ... };

    The list must contain an even number of elements.

    When called with a key/value list rather than a hash reference,
    `with_hash` constructs an internal hash for the duration of the block.
    Writes inside the block update this internal hash, not the caller's variables.

- A final coderef (required)

    The last argument must be a coderef. It receives no parameters; instead,
    lexical aliases are created for each hash key.

### Behaviour

Inside the coderef:

- Each hash key becomes a lexical variable

        $foo   # alias to $hash{foo}
        $bar   # alias to $hash{bar}

- Assigning to a lexical updates the original hash

        $foo = 42;   # sets $hash{foo} = 42

- Reading the lexical reads from the hash
- Aliases are removed when the coderef returns

### Error Handling

`with_hash` throws descriptive exceptions when:

- No coderef is provided
- A hash list has an odd number of elements
- Extra arguments appear after the coderef
- The hash argument is neither a hashref nor a valid key/value list

These errors are intended to catch common mistakes early and make test
failures easier to diagnose.

### Return Value

Returns whatever the coderef returns.

### Examples

Using a hashref:

    my %config = ( host => 'localhost', port => 3306 );

    with_hash \%config, sub {
        say "$host:$port";   # prints "localhost:3306"
        $port = 3307;        # updates %config
    };

Using a hash list:

    with_hash debug => 1, retries => 3, sub {
        $retries++;          # modifies the underlying hash
    };

With flags:

    with_hash strict => \%opts, sub {
        ...
    };

### Notes

`with_hash` is intended for small, self-contained blocks where aliasing
improves clarity. It is not a general-purpose replacement for normal hash
access, nor does it attempt to provide full lexical scoping tricks beyond
simple aliasing.

### with vs. with\_hash

Although `with` and `with_hash` share a similar calling style, they serve
different purposes and operate at different levels of abstraction.

#### `with` - the low-level aliasing engine

`with` is the core primitive. It expects:

    with \%hash, sub { ... };

It assumes that:

- The first argument is already a valid hash reference
- The last argument is a coderef
- Any flags have already been parsed
- The hash keys are suitable for use as lexical variable names

`with` performs no argument normalization. It simply creates lexical aliases
for each key in the provided hash and executes the coderef. It is strict,
minimal, and intended for internal use or advanced callers who want full
control.

#### `with_hash` - the user-friendly wrapper

`with_hash` is the public, ergonomic interface. It accepts a much more
flexible argument style:

    with_hash a => 1, b => 2, sub { ... };
    with_hash \%hash, sub { ... };
    with_hash strict => a => 1, b => 2, sub { ... };

`with_hash` is responsible for:

- Parsing optional flags
- Accepting either a hash reference OR a key/value list
- Validating argument structure (even key/value pairs, final coderef, etc.)
- Converting key/value lists into a hash reference
- Producing clear, user-facing error messages
- Calling `with` with a normalized hashref and the coderef

In other words, `with_hash` does all the DWIM work so that users can write
clean, concise code without worrying about argument shape or validation.

#### Summary

- Use `with_hash` in normal code.
- Use `with` only when you already have a validated hashref and want
direct access to the aliasing mechanism.

`with_hash` is the safe, friendly API.
`with` is the strict,
low-level engine that powers it.

### Key Filtering: `-only` and `-except`

`with_hash` supports two optional flags that control which keys from the
input hash are exposed as lexical aliases inside the block.

These flags allow you to limit or refine the set of variables created,
making aliasing more intentional and avoiding namespace clutter.

#### `-only =` \\@keys>

    with_hash -only => [qw/foo bar/], \%hash, sub {
        say $foo;   # alias to $hash{foo}
        say $bar;   # alias to $hash{bar}
    };

Only the listed keys are aliased. Any keys not listed are ignored. Keys that
do not exist in the hash are silently skipped.

#### `-except =` \\@keys>

    with_hash -except => [qw/debug verbose/], \%hash, sub {
        say $host;   # ok
        say $port;   # ok
        # $debug is NOT aliased
    };

All keys except those listed are aliased.

#### Rules and Validation

- `-only` and `-except` are mutually exclusive.
Using both at the same time results in an error.
- Both flags require an array reference. Anything else triggers an error.
- Filtering is applied **before** renaming or strict key validation.
Filtering temporarily hides keys from the underlying hash during the with() call.
Keys not selected by only/except are removed before aliasing and restored afterwards,
ensuring that write-through aliasing always affects the original hash.
- If filtering removes all keys, the block still runs normally; no aliases are
created.

#### Error Handling

All validation errors are raised via `Croak`, so error messages correctly
report the caller's file and line number.

### -rename => { OLDKEY => NEWLEX, ... }

The `-rename` flag allows you to expose hash keys under different lexical
variable names inside the `with_hash` block.

This is useful when the original hash keys are not valid Perl identifiers
(e.g. contain hyphens), or when you want more convenient or descriptive
lexical names.

    with_hash
        -rename => {
            'http-status' => 'status',
            'user_id'     => 'user',
        },
        \%hash,
        sub {
            say $status;   # alias to $hash{'http-status'}
            say $user;     # alias to $hash{'user_id'}
        };

Renaming does **not** copy values.  The new lexical name is aliased directly
to the original hash slot, so write-through works as expected:

    $status = 404;   # updates $hash{'http-status'}
    $user   = 99;    # updates $hash{'user_id'}

#### Interaction with filtering

Renaming happens **after** `-only` / `-except` filtering.  Filtering selects
which keys are visible; renaming changes the lexical names of those keys.

For example:

    with_hash
        -only   => [qw/http-status foo/],
        -rename => { 'http-status' => 'status' },
        \%hash,
        sub {
            say $status;   # ok
            say $foo;      # ok
            say $user;     # undef (not selected by -only)
        };

#### Interaction with strict mode

When `-strict` is enabled, every renamed lexical must be declared in the
outer scope.  If a renamed lexical does not exist, `with_hash` will croak:

    my ($status);   # but NOT $missing_lex

    with_hash
        -strict,
        -rename => { 'http-status' => 'missing_lex' },
        \%hash,
        sub { ... };

This dies with:

    strict mode: lexical $missing_lex not declared in outer scope

#### Validity of new names

The new lexical name must be a valid Perl identifier:

    /^[A-Za-z_]\w*$/

If the new name is invalid, the key is ignored (or causes an error under
`-strict`).

#### Summary

- Renames hash keys to different lexical variable names.
- Write-through updates the original hash.
- Works with `-only` and `-except`.
- Respects `-strict` (renamed lexicals must exist).
- Does not copy values; aliases directly to the original storage.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# LIMITATIONS

`with()` uses PadWalker to manipulate lexical pads.
This is fast enough for normal use, but not intended for tight loops or high-frequency calls.

- Lexicals must be declared in the outer scope.
- Only hashrefs are supported.
- Only keys matching `/^[A-Za-z_]\w*$/` are eligible.

# AUTHOR

Nigel Horne

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
