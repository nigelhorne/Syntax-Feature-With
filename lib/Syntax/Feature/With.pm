package Syntax::Feature::With;

use strict;
use warnings;
use Exporter 'import';
use PadWalker qw(closed_over set_closed_over);

our @EXPORT_OK = qw(with);
our $VERSION = '0.01';

=head1 NAME

Syntax::Feature::With - Simulate Pascal's "with" statement in Perl

=head1 NAME

Syntax::Feature::With - Lightweight lexical aliasing into a coderef using PadWalker

=head1 SYNOPSIS

    use Syntax::Feature::With qw(with);

    my %h = ( a => 'b', x => 42 );

    # Lexicals must be declared in the outer scope
    my ($a, $x);

    with(\%h, sub {
        print "$a\n";   # prints "b"
        print "$x\n";   # prints "42"

        $a = 'changed'; # writes back into %h
    });

    say $h{a};          # "changed"

=head1 DESCRIPTION

C<with()> provides a simple, predictable way to temporarily alias hash
keys into lexical variables inside a coderef. It is intentionally small,
pure-Perl, and implemented using L<PadWalker>.

This module does B<not> introduce new syntax. Instead, it gives you a
clean functional interface:

    with(\%hash, sub { ... });

Inside the coderef, selected lexicals become read/write aliases to the
corresponding hash entries.

=head1 HOW IT WORKS

C<with()> inspects the coderef's lexical pad using PadWalker. For each
valid hash key:

=over 4

=item *

If a lexical of the same name (e.g. C<$a> for key C<a>) exists in the
coderef's closure pad, it is replaced with a reference to the hash slot.

=item *

Assignments to that lexical write back into the hash.

=item *

Reads from that lexical read from the hash.

=back

Because PadWalker can only modify lexicals that already exist in the
coderef's closure pad, you must declare the lexicals in the outer scope:

    my ($a, $b);
    with(\%h, sub { ... });

Declaring them inside the coderef will not work.

=head1 USAGE

=head2 with(\%hash, sub { ... })

The first argument must be a hash reference.  
The second argument must be a coderef.

Example:

    my %h = ( foo => 1, bar => 2 );
    my ($foo, $bar);

    with(\%h, sub {
        $foo++;     # updates $h{foo}
        $bar = 99;  # updates $h{bar}
    });

=head1 VALID IDENTIFIERS

Only hash keys matching:

    /^[A-Za-z_]\w*$/

are considered valid Perl identifiers and eligible for aliasing.

All others are silently ignored.

=head1 UNDECLARED LEXICALS

If a lexical is not declared in the outer scope, it is B<not> created or
aliased. It simply remains C<undef> inside the coderef.

Example:

    my %h = ( a => 123 );

    with(\%h, sub {
        say $a;   # undef, not aliased
    });

This behaviour is intentional and avoids surprising magic.

=head1 RETURN VALUE

C<with()> returns whatever the coderef returns.

=head1 ERROR HANDLING

C<with()> will throw an exception if:

=over 4

=item *

The first argument is not a hash reference.

=item *

The second argument is not a coderef.

=back

All other behaviour is strict-mode friendly and predictable.

=head1 LIMITATIONS

This module is intentionally simple. It does B<not>:

=over 4

=item *

create new lexicals inside the coderef

=item *

alias array elements or object attributes

=item *

introduce new syntax

=item *

rewrite Perl code or manipulate the optree

=back

If you need deeper integration (keywords, syntax, chained method
aliasing, etc.), you will need an XS-based keyword module.


=cut

sub with {
    my ($hashref, $code) = @_;

    die "with: first argument must be a hashref"
        unless ref($hashref) eq 'HASH';

    die "with: second argument must be a coderef"
        unless ref($code) eq 'CODE';

    # Get the coderef’s lexical pad
    my $closed = closed_over($code);

    # Copy it so we can modify it
    my %new = %$closed;

    # For each valid key, alias the lexical
    for my $key (keys %$hashref) {
        next unless $key =~ /^[A-Za-z_]\w*$/;   # valid Perl identifier
        my $var = '$' . $key;
        next unless exists $new{$var};          # only alias declared lexicals
        $new{$var} = \$hashref->{$key};         # alias
    }

    # Install the modified pad
    set_closed_over($code, \%new);

    # Execute the coderef
    return $code->();
}

=head1 SEE ALSO

L<PadWalker>, L<Sub::Util>, L<Lexical::Alias>

=head1 AUTHOR

Nigel Horne <njh@nigelhorne.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
