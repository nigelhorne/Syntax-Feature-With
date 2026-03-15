package Syntax::Feature::With;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(with);
our $VERSION = '0.01';

=head1 NAME

Syntax::Feature::With - Simulate Pascal's "with" statement in Perl

=head1 SYNOPSIS

    use Syntax::Feature::With qw(with);

    my $person = {
        Name => 'Alice',
        Age  => 30
    };

    with($person, sub {
        my %fields = @_;
        print "Name: $fields{Name}\n";
        print "Age: $fields{Age}\n";
    });

=head1 DESCRIPTION

This module provides a C<with> function similar to Pascal's C<with> statement.
It allows you to pass a hash reference and a code block, and inside the block
you can access the hash's keys as if they were local variables.

=head1 FUNCTIONS

=head2 with( \%hash, sub { ... } )

Executes the given code block with the hash's key-value pairs passed in as
arguments.

=cut

sub with {
	my ($hash_ref, $code_ref) = @_;

	# Validate arguments
	die 'First argument must be a hash reference' unless ref($hash_ref) eq 'HASH';
	die 'Second argument must be a code reference' unless ref($code_ref) eq 'CODE';

	# Pass hash key-value pairs to the code block
	return $code_ref->(%{$hash_ref});
}

=head1 AUTHOR

Nigel Horne <njh@nigelhorne.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
