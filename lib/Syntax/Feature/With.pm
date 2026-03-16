package Syntax::Feature::With;

use strict;
use warnings;

use Exporter 'import';
use PadWalker qw(closed_over set_closed_over);

our @EXPORT_OK = qw(with with_hash);

our $VERSION = '0.01';

# Track nested with() depth for trace/debug output
my $WITH_DEPTH = 0;

=head1 NAME

Syntax::Feature::With - Simulate Pascal's "with" statement in Perl

=head1 SYNOPSIS

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

=head1 DESCRIPTION

C<with()> provides a simple, predictable way to temporarily alias hash
keys into lexical variables inside a coderef. It is implemented using
L<PadWalker> and requires no XS, no parser hooks, and no syntax changes.

=head1 FEATURES

=head2 Read/write aliasing

Lexicals declared in the outer scope become aliases to hash entries:

    my ($a);
    with \%h, sub { $a = 10 };   # updates $h{a}

=head2 Strict mode

    with -strict => \%h, sub { ... };

Every valid hash key must have a matching lexical declared in the outer
scope. Missing lexicals cause an immediate error.

=head2 Debug mode

    with -debug => \%h, sub { ... };

Prints a summary of aliasing decisions:

    Aliased: $a -> %hash{a}
    Ignored: foo-bar (invalid identifier)
    Ignored: y (no lexical declared)

=head2 Trace mode

    with -trace => \%h, sub { ... };

Shows entry/exit and nesting depth:

    [with depth=1] entering with()
    Aliased: $a -> %hash{a}
    [with depth=1] leaving with()

Trace mode implies debug mode.

=head2 Nested with() support

Nested calls work naturally:

    with \%h1, sub {
        with \%h2, sub {
            ...
        };
    };

=head2 with_hash wrapper

Syntactic sugar:

    with_hash %h => sub { ... };

=cut

# ------------------------------------------------------------
# with() — main entry point
# ------------------------------------------------------------
sub with {
	my @args = @_;

	# --------------------------------------------------------
	# Parse flags
	# --------------------------------------------------------
	my %opts = (
		strict => 0,
		debug  => 0,
		trace  => 0,
	);

	while (@args && $args[0] =~ /^-(strict|debug|trace)$/) {
		my $flag = shift @args;
		$flag =~ s/^-//;
		$opts{$flag} = 1;
	}

	# trace implies debug
	$opts{debug} = 1 if $opts{trace};

	# --------------------------------------------------------
	# Extract hashref + coderef
	# --------------------------------------------------------
	my ($href, $code) = @args;

	die "with(): first argument must be a hashref" unless ref($href) eq 'HASH';

	die "with(): second argument must be a coderef" unless ref($code) eq 'CODE';

	# --------------------------------------------------------
	# Trace: entering
	# --------------------------------------------------------
	$WITH_DEPTH++;
	if ($opts{trace}) {
		warn "[with depth=$WITH_DEPTH] entering with()";
	}

	# --------------------------------------------------------
	# Get closure pad of the coderef
	# --------------------------------------------------------
	my $closed = closed_over($code);
	my %newpad = %$closed;

	# --------------------------------------------------------
	# Process each hash key
	# --------------------------------------------------------
	KEY: for my $key (keys %$href) {

		# Valid Perl identifier?
		unless ($key =~ /^[A-Za-z_]\w*$/) {
			warn "Ignored: $key (invalid identifier)" if $opts{debug};
			next KEY;
		}

		my $var = '$' . $key;

		# Lexical declared in outer scope?
		unless (exists $newpad{$var}) {
			if ($opts{strict}) {
				die "with(): strict mode: lexical \$$key not declared in outer scope";
			}
			warn "Ignored: $key (no lexical declared)" if $opts{debug};
			next KEY;
		}

		# Alias lexical to hash slot
		$newpad{$var} = \$href->{$key};

		warn "Aliased: \$$key => \%hash{$key}" if $opts{debug};
	}

	# --------------------------------------------------------
	# Install modified pad
	# --------------------------------------------------------
	set_closed_over($code, \%newpad);

	# --------------------------------------------------------
	# Execute coderef
	# --------------------------------------------------------
	my $result = $code->();

	# --------------------------------------------------------
	# Trace: leaving
	# --------------------------------------------------------
	if ($opts{trace}) {
		warn "[with depth=$WITH_DEPTH] leaving with()";
	}
	$WITH_DEPTH--;

	return $result;
}

# ------------------------------------------------------------
# with_hash() — convenience wrapper
# ------------------------------------------------------------
sub with_hash {
	my @args = @_;

	# Extract flags
	my @flags;
	while (@args && $args[0] =~ /^-(strict|debug|trace)$/) {
		push @flags, shift @args;
	}

	# Last argument must be a coderef
	my $code = pop @args;
	die 'with_hash(): last argument must be a coderef' unless ref($code) eq 'CODE';

	my $href;

	if (@args == 1 && ref($args[0]) eq 'HASH') {
		# Case 1: with_hash \%h, sub { ... }
		$href = shift @args;
	} else {
		# Case 2: with_hash %h => sub { ... }
		# If the first arg is a HASHREF but there is more than one arg,
		# this is invalid (extra junk).
		if (@args >= 1 && ref($args[0]) eq 'HASH') {
			die "with_hash(): hashref must be the only argument before coderef";
		}

		# Must be an even-sized hash list
		die 'with_hash(): odd number of elements in hash list' if @args % 2;

		my %h = @args;
		$href = \%h;
	}

	return with(@flags, $href, $code);
}

1;

__END__

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LIMITATIONS

=over 4

=item *

Lexicals must be declared in the outer scope.

=item *

Only hashrefs are supported.

=item *

Only keys matching C</^[A-Za-z_]\w*$/> are eligible.

=back

=head1 AUTHOR

Nigel Horne

=head1 REPOSITORY

L<https://github.com/nigelhorne/Syntax-Feature-With>

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-syntax-feature-with at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Syntax-Featre-With>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Syntax-Feature-With

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/Syntax-Featre-With>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Syntax-Featre-With>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Syntax-Featre-With>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Syntax-Featre-With>

=back

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
